function! Printc(counters, width)
    let result = ""
    let idx=0
    while idx < len (a:width)
        if a:width[idx] > 0 
            if type(a:counters[idx]) == 5
                let result = result . printf("%" . a:width[idx] . 's', Mul1k(a:counters[idx]))
            elseif idx == 0
                let result = result . printf("%-" . a:width[idx] . 's', a:counters[idx]) . ": "
            elseif idx == 1
                let result = result . printf("%-" . a:width[idx] . 's', a:counters[idx])
            else
                let result = result . printf("%" . a:width[idx] . 'd', a:counters[idx])
            end
        endif
        let idx += 1
    endwhile
    return result
endfunction


function! CpmQStats()
	let save_cursor = getpos(".")
    let found = 0
    let iter = -1
    let data = {}
    execute "normal! gg"
    if search('\v^  \[cpmqstats\]$', "W") == 0
        return
    endif
    if foldlevel(line(".")) > 0 
        execute 'normal! zO'
        execute "normal! ]z"
        let end = line(".")
        execute "normal! [z"
        let start = line(".")
    else
        let start = 1
        let end = "$"
    endif
    let lines=getline(start,end)
    let q_data_p = []
    for line in lines
        if line =~# '\v^  \[cpmqstats\]$'
            let nRow = 0
            let found = 1
            let iter += 1
            if iter > 4 | break | endif 
        elseif found
            if line !~# '\v^  Q\['
                let found = 0
                continue
            endif
            let q_data = matchlist(line, '\v^  Q\[ *(\d+)\]: (.*) +[\*]?fwd stats =\D+(\d+)\/(\d+), \d+\/\d+\)\ +drop stats =\D+(\d+)\/(\d+), \d+\/\d+\)')
            let q_name = "q_" . printf("%03d", q_data[1])
            for idx in range(3, 6)
                let q_data[idx] = Div1k(q_data[idx])
            endfor
            let q_data = [substitute(q_data[2], '^\s*\(.\{-}\)\s*$', '\1', '')] + q_data[3:6]
            if iter == 0
                let data[q_name] = deepcopy(q_data)
                let q_data_p += [deepcopy(q_data)]
            else
                let index = 1
                while index < len(q_data)
                    let data[q_name] += [(q_data[index] - q_data_p[nRow][index])]
                    let index += 1
                endwhile
                let q_data_p[nRow] = deepcopy(q_data)
            endif
            let nRow += 1
        endif
    endfor
	call setpos('.', save_cursor)
    call NewTab("CpmQStats")
    let print_template = [["Forwarded packets:", 25, 25, 0, 0, 0, 10, 0, 0, 0, 10, 0, 0, 0, 10, 0, 0, 0, 10, 0, 0, 0],
                         \["Forwarded octets:",  25,  0, 25, 0, 0, 0, 10, 0, 0, 0, 10, 0, 0, 0, 10, 0, 0, 0, 10, 0, 0],
                         \["Dropped:",           25, 0, 0, 12, 13, 0, 0, 6, 7, 0, 0, 6, 7, 0, 0, 6, 7, 0, 0, 6, 7]]
    let q_names = sort(keys(data))
    for templ in print_template
        call append(line("$"), templ[0])
        for q_name in q_names
            call append(line("$"), q_name . ": " . Printc(data[q_name], templ[1:-1]))
        endfor
        call append(line("$"), "")
    endfor
endfunction


function! GetFoldSection(cmd_string)
	let save_cursor = getpos(".")
    execute "normal! gg"
    let lines = []
    while 1
        if search(a:cmd_string, "W") == 0
            break
        endif
        if foldlevel(line(".")) > 0 
            execute 'normal! zv'
            let start = line(".")
            execute "normal! ]z"
            let end = line(".")
"           execute "normal! [z"
"           let start = line(".")
            execute 'normal! zcj'
            let lines += getline(start,end)
        else
            let lines = getline(1,"$")
            break
        endif
    endwhile
	call setpos('.', save_cursor)
    return lines
endfunction


function! SnapQStats()
    let data = {}
    let lines = GetFoldSection(' Delta Queue Stats for Slot ')
    for line in lines
        "echo line
        if line =~# '\v^\d{1,2}: {3}Q\['
            let q_data = matchlist(line, '\v^\d{1,2}: {3}Q\[ *(\d+)\]')
            let q_name = complex . "_" . q_data[1]
"           let q_name = complex . "_" . printf("%05d", q_data[1])
            let q_data = matchlist(line, '\v^\d{1,2}: {3}Q\[ *\d+\]: (.*) +[\*]?fwd stats =\D+(\d+)\/(\d+), (\d+)\/(\d+)\)\ +drop stats =\D+(\d+)\/(\d+), (\d+)\/(\d+)')
            for idx in range(2, 9)
                let q_data[idx] = Div1k(q_data[idx])
            endfor
            let q_data = [substitute(q_data[1], '^\s*\(.\{-}\)\s*$', '\1', '')] + [(q_data[2]+q_data[4])*100/delta] 
            \ + [(q_data[3]+q_data[5])*800/delta] + [(q_data[6]+q_data[8])*100/delta] + [(q_data[7]+q_data[9])*800/delta]
            if has_key(data, q_name)
                echoe "Double Q name: " . q_name
                return
            endif
            let q_data = [q_name] + q_data 
            let data[q_name] = deepcopy(q_data)
        elseif line =~# '\v^\d{1,2}: {3}\d{1,2}[A-H]-'
            let q_data = matchlist(line, '\v^\d{1,2}: {3}(\d{1,2})([A-H])-([E|I|Q])')
            let complex = printf("%02d", q_data[1]) . q_data[2]. q_data[3]
        elseif line =~# '\v^\d{1,2}: {3}Delta ticks \d{3}'
            let delta = matchlist(line, '\v^\d{1,2}: {3}Delta ticks (\d{3})')[1]
        endif
    endfor
    call NewTab("SnapQStats")
    let templ = ["Delta queue stats:", 15, 35, 15, 20, 15, 20]
    let q_names = sort(keys(data))
    call append(line("$"), templ[0])
    for q_name in q_names
        call append(line("$"), Printc(data[q_name], templ[1:-1]))
    endfor
    call append(line("$"), "")
endfunction



function! DeltaQStats(tab_nbr)
    let lines1 = GetFoldSection('All active queue and policer stats')
    let hbs1 = GetTimeStamp(1)
    execute 'normal! ' . a:tab_nbr . 'gt'
    let hbs2 = GetTimeStamp(1)
    let slot1 = sort(keys(hbs1))[0]
    let timediff = hbs2[slot1] - hbs1[slot1]
    let lines2 = GetFoldSection('All active queue and policer stats')
    let q_sum1 = ["", "", 0.0, 0.0, 0.0, 0.0]
    let q_sum2 = ["", "", 0.0, 0.0, 0.0, 0.0]
    let data1 = Lines2Qdata(lines1)
    let data2 = Lines2Qdata(lines2)
    for q_name in keys(data2)
        if !has_key(data1, q_name)
            let data1[q_name] = [q_name, data2[q_name][1], 0.0, 0.0, 0.0, 0.0]
        endif
        for idx in range(2, 5)
            let data2[q_name][idx] = data2[q_name][idx] - data1[q_name][idx]
            let q_sum2[idx] += data2[q_name][idx]
            if idx == 3 || idx == 5
                let data1[q_name][idx] = data2[q_name][idx] / timediff * 8
            else
                let data1[q_name][idx] = data2[q_name][idx] / timediff
            endif
            let q_sum1[idx] += data1[q_name][idx]
        endfor
    endfor    
    let data1["Sum       "] = deepcopy(q_sum1)
    let data2["Sum       "] = deepcopy(q_sum2)
    call NewTab("DeltaQStats")
    let templ = ["Delta queue stats for delta of " . timediff . " seconds:", 14, 30, 20, 30, 20, 30]
    let q_names = sort(keys(data2))
    call append(line("$"), templ[0])
    for q_name in q_names
        if data2[q_name][3] > 0 || data2[q_name][5] > 0
            call append(line("$"), Printc(data2[q_name], templ[1:-1]))
        endif
    endfor
    call append(line("$"), "")
    let templ = ["Delta queue stats in PPS and bps", 14, 30, 16, 20, 16, 20]
    let q_names = sort(keys(data1))
    call append(line("$"), templ[0])
    for q_name in q_names
        if data1[q_name][3] > 0 || data1[q_name][5] > 0
            call append(line("$"), Printc(data1[q_name], templ[1:-1]))
        endif
    endfor
    call append(line("$"), "")
endfunction

function! Lines2Qdata(lines)
    let data = {}
    for line in a:lines
        if line =~# '\v^\d{1,2}: {3}Q\a-'
            let q_data = matchlist(line, '\v^\d{1,2}: {3}([QP]\a-[E|I]-\d{1,5}) +: (.{-}) *\*?Fwd')
"           let q_name = complex . "_" . printf("%05d", q_data[1])
            let q_name = complex . "_" . q_data[1]
            let q_descr = substitute(q_data[2], '\v^(.{-})\s*$', '\1', '')
            if line =~ '\vFwd.{-}\=\d+\/\d+.{-}Drop\=.{-}\d+\/\d+'
                let q_data = matchlist(line, '\vFwd.{-}\=(\d+)\/(\d+).{-}Drop\=.{-}(\d+)\/(\d+)')[1:4]
                for idx in range(0, 3)
                    let q_data[idx] = Div1k(q_data[idx])
                endfor
            else
                let q_data = matchlist(line, '\vFwd.{-}\=(\d+)\/(\d+).{-} +Fwd.{-}\=(\d+)\/(\d+) +Drop.{-}(\d+)\/(\d+) +Drop.{-}\=(\d+)\/(\d+)')
                for idx in range(1, 8)
                    let q_data[idx] = Div1k(q_data[idx])
                endfor
                let q_data = [q_data[1]+q_data[3]] + [q_data[2]+q_data[4]] + [q_data[5]+q_data[7]] + [q_data[6]+q_data[8]]
            endif
            let q_data = [q_name, q_descr] + q_data 
            if has_key(data, q_name)
                echoe "Double Q name: " . q_name
                echoe "Line: " . line
                return
            endif
            let data[q_name] = deepcopy(q_data)
        elseif line =~# '\v^\d{1,2}:   Complex [A-H] - [I|E|C|P]'
            let q_data = matchlist(line, '\v^(\d{1,2}):   Complex ([A-H) - ([I|E|C|P])')
            let complex = printf("%02d", q_data[1]) . q_data[2]. q_data[3]
        endif
    endfor
    return data
endfunction

function! NewTab(file_n)
    exe ":tabnew"
    exe ":tabmove"
    exe ":silent file " . a:file_n . tabpagenr() 
endfunction

function! Div1k(div)
    if strlen(a:div) > 3 
        let result = str2float(substitute(a:div, '\(\d\{3\}\)$', '\.\1', ''))
    else
        let result = a:div/1000.0
    endif
    return result
endfunction

function! Div1m(div)
    if strlen(a:div) > 6
        let result = str2float(substitute(a:div, '\(\d\{6\}\)$', '\.\1', ''))
    else
        let result = a:div/1000000.0
    endif
    return result
endfunction

function! Mul1k(mul)
    if a:mul < 1
        let result = printf("%0.0f", a:mul * 1000)
    else
        let result = substitute(printf("%0.3f", a:mul), '\.\(\d\d\d\)', '\1', '')
        let result = substitute(result, '\(\d\)\(\(\d\d\d\)\+\d\@!\)\@=', '\1,', 'g')
    endif
    return result
endfunction

function! Mul1m(mul)
    if a:mul < 1
        let result = printf("%0.0f", a:mul * 1000000)
    else
        let result = substitute(printf("%0.6f", a:mul), '\.\(\d\d\d\)', '\1', '')
    endif
    let result = substitute(result, '\(\d\)\(\(\d\d\d\)\+\d\@!\)\@=', '\1,', 'g')
    return result
endfunction

function! Strip(input_string)
    return substitute(a:input_string, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction


function! PortCompare(p1, p2)
    let p1 = matchlist(a:p1, '\v^(\d{1,2})/(\d{1})/(\d{1,2})(\.(0x\x{1,4}))?')
    let p2 = matchlist(a:p2, '\v^(\d{1,2})/(\d{1})/(\d{1,2})(\.(0x\x{1,4}))?')
    if !get(p1, 1) || !get(p2, 1)
        return a:p1 > a:p2 ? 1 : -1
    endif
    if p1[1] != p2[1]
        return str2nr(p1[1]) > str2nr(p2[1]) ? 1 : -1
    elseif p1[2] != p2[2]
        return str2nr(p1[2]) > str2nr(p2[2]) ? 1 : -1
    elseif p1[3] != p2[3]
        return str2nr(p1[3]) > str2nr(p2[3]) ? 1 : -1
    else
        return str2nr(p1[5], 16) > str2nr(p2[5], 16) ? 1 : -1
    endif
endfunction

function! SnapPStats()
    let lines = GetFoldSection(' Delta Port Stats for Slot ')
    let c_names = ["ifInOctets", "ifInUcastPkts", "ifInMulticastPkts", "ifInBroadcastPkts", "ifOutOctets", "ifOutUcastPkts",
                \ "ifOutMulticastPkts", "ifOutBroadcastPkts", "qosDiscards", "snapshot delta ticks"]
    let p_sum = ["Sum :", 0.0, 0.0, 0.0, 0.0, 0.0]
    let data = Lines2pdata(lines, c_names)
    for p_name in keys(data)
        let data[p_name] = [data[p_name][0], data[p_name][1] * 800 / data[p_name][-2]] + [data[p_name][2] * 100 / data[p_name][-2]] +
            \[data[p_name][3] * 100 / data[p_name][-2]] + [data[p_name][4] * 800 / data[p_name][-2]] + [data[p_name][5] * 100 / data[p_name][-2]]
        for idx in range(1, 5)
            let p_sum[idx] += data[p_name][idx]
        endfor
    endfor    
    let data["Sum"] = deepcopy(p_sum)
    call NewTab("SnapPStats")
    let templ = ["Delta port stats:", 14, 18, 14, 14, 18, 14]
    let p_names = sort(keys(data), "PortCompare")
    call append(line("$"), templ[0])
    for p_name in p_names
        call append(line("$"), Printc(data[p_name], templ[1:-1]))
    endfor
    call append(line("$"), "")
endfunction



function! DeltaPStats(tab_nbr, ...)
    let data = {}
    let lines1 = GetFoldSection('  Dumping port stats Slot ')
    let timestamp1 = GetTimeStamp()
    execute 'normal! ' . a:tab_nbr . 'gt'
    let timestamp2 = GetTimeStamp()
    let timediff = timestamp2 - timestamp1
    let lines2 = GetFoldSection('  Dumping port stats Slot ')
    let c_names = ["ifInOctets", "ifInUcastPkts", "ifInMulticastPkts", "ifInBroadcastPkts", "ifOutOctets", "ifOutUcastPkts",
                \ "ifOutMulticastPkts", "ifOutBroadcastPkts", "qosDiscards"]
    let p_sum1 = ["Sum", 0.0, 0.0, 0.0, 0.0, 0.0, {}]
    let p_sum2 = ["Sum", 0.0, 0.0, 0.0, 0.0, 0.0, {}]
    let data1 = Lines2pdata(lines1, c_names)
    let data2 = Lines2pdata(lines2, c_names)
    for p_name in keys(data1)
        for idx in range(1, 5)
            let data2[p_name][idx] = data2[p_name][idx] - data1[p_name][idx]
            let p_sum2[idx] += data2[p_name][idx]
            if idx == 1 || idx == 4
                let data1[p_name][idx] = data2[p_name][idx] / timediff * 8
            else
                let data1[p_name][idx] = data2[p_name][idx] / timediff
            endif
            let p_sum1[idx] += data1[p_name][idx]
        endfor
        if a:0 >= 1
            for i_err in keys(data2[p_name][6])
                if !has_key(data1[p_name][6], i_err)
                    let data1[p_name][6][i_err] = 0.0
                endif
                if !has_key(p_sum1[6], i_err)
                    let p_sum1[6][i_err] = 0.0
                endif
                if !has_key(p_sum2[6], i_err)
                    let p_sum2[6][i_err] = 0.0
                endif
                let data2[p_name][6][i_err] -=  data1[p_name][6][i_err]
                let p_sum2[6][i_err] += data2[p_name][6][i_err]
                let data1[p_name][6][i_err] = data2[p_name][6][i_err] / timediff
                let p_sum1[6][i_err] += data1[p_name][6][i_err]
            endfor
        else
            let data1[p_name] = data1[p_name][0:5]
            let data2[p_name] = data2[p_name][0:5]
        endif
    endfor    
    let data1["Sum"] = deepcopy(p_sum1)
    let data2["Sum"] = deepcopy(p_sum2)
    call NewTab("DeltaPStats")
    let templ = ["Delta port stats for delta of " . timediff . " seconds:", 14, 30, 20, 20, 30, 20]
    let p_names = sort(keys(data2), "PortCompare")
    call append(line("$"), templ[0])
    for p_name in p_names
        call append(line("$"), Printc(data2[p_name], templ[1:-1]))
        if a:0 >= 1
            for i_err in keys(data2[p_name][6])
                if data2[p_name][6][i_err] > 0
                    "let result = printf("%" . templ[1]+templ[2]+templ[3] . 's', i_err)
                    let result = printf("%66s", i_err)
                    let result = result . printf("%" . templ[4] . 's', Mul1k(data2[p_name][6][i_err]))
                    call append(line("$"), result)
                endif
            endfor
        endif
    endfor
    call append(line("$"), "")
    let templ = ["Delta port stats in PPS and bps:", 14, 20, 16, 16, 20, 16]
    let p_names = sort(keys(data1), "PortCompare")
    call append(line("$"), templ[0])
    for p_name in p_names
        call append(line("$"), Printc(data1[p_name], templ[1:-1]))
        if a:0 >= 1
            for i_err in keys(data1[p_name][6])
                if data1[p_name][6][i_err] > 0
                    "let result = printf("%" . templ[1]+templ[2]+templ[3] . 's', i_err)
                    let result = printf("%52s", i_err)
                    let result = result . printf("%" . templ[4] . 's', Mul1k(data1[p_name][6][i_err]))
                    call append(line("$"), result)
                endif
            endfor
        endif
    endfor
    call append(line("$"), "")
endfunction

function! GetTimeStamp(...)
	let save_cursor = getpos(".")
    if a:0 > 0
        let heartbeats = {}
        let lines = GetFoldSection('  Current card health')
        for line in lines
            if line =~# '\vSlot +\d+, Present\? Y.*State: Running'
                let hb_data = matchlist(line, '\vSlot +(\d+), Present\? Y.*State: Running.*LastHb (\d+)')
                let slot = printf("%02d", hb_data[1])
                let hbs = hb_data[2]/10
                let heartbeats[slot] = hbs
            endif
        endfor
        call setpos('.', save_cursor)
        return heartbeats
    else
    "   if search('\v  Current timestamp .* vxTicks \= 0x\x+', "w") == 0
        if search('\v^  Current vxTicks \= ', "w") == 0
            return 0
        endif
    "   let timestamp = matchlist(getline("."), '\v^  Current timestamp .* vxTicks \= (0x\x+)')[1]
        let timestamp = matchlist(getline("."), '\v^  Current vxTicks \= (0x\x+)')[1]
        call setpos('.', save_cursor)
        return timestamp / 100
    endif
endfunction

function! Lines2pdata(lines, c_names)
    let data = {}
    let i_err_det = {}
    let found = 0
    for line in a:lines
        if line =~# '\v\C^\d{1,2}: {3}\[(Port|Channel) id '
            let p_name = matchlist(line, '\v\C^\d{1,2}: {3}\[(Port|Channel) id (.+)\]')[2]
            let found = 1
            let p_data = repeat([0], len(a:c_names))
            let i_errors = 0
            let i_err_det = {}
        elseif found && line =~ '\v^\d{1,2}:\s*$'
            let found = 0
            let i_errors = Div1k(string(i_errors))
            let delta_ticks = p_data[-1]
            let p_data = [p_data[0]] + [p_data[1]+p_data[2]+p_data[3]] + [i_errors] + 
                        \ [p_data[4]] + [p_data[5]+p_data[6]+p_data[7]]
            let sum_ctr = 0
            for cntr in p_data
                let sum_ctr += cntr
            endfor
            if sum_ctr > 0
                if a:c_names[-1] == "snapshot delta ticks"
                    let p_data += [delta_ticks]
                endif
                if has_key(data, p_name)
                    echoe "Double port/channel name: " . p_name
                    for line1 in a:lines
                        echo line1
                    endfor
                    return
                endif
                let p_data = [p_name] + p_data + [i_err_det]
                let data[p_name] = deepcopy(p_data)
            endif
        endif
        if found
            let idx = 0
            for c_name in a:c_names
                if line =~# '\v\C^\d{1,2}: {7}' . c_name
                    if c_name == "qosDiscards"
                        let errors = matchlist(line, '\v\C^\d{1,2}: {7}' . c_name . ' {3,}\[\d+\] (\d+) pkts')[1]
                        let i_errors += errors
                        let i_err_det[c_name] = Div1k(errors)
                    else
                        let p_data[idx] = matchlist(line, '\v\C^\d{1,2}: {7}' . c_name . ' {3,}(\d+)\s*$')[1]
                        if c_name != "snapshot delta ticks"
                            let p_data[idx] = Div1k(p_data[idx])
                        endif
                    endif
                endif
                let idx += 1
            endfor  
            if line =~# '\v^\d{1,2}: {11}(\D+)(\d+)'
                let errors = matchlist(line, '\v^\d{1,2}: {11}(\D+)(\d+)')
                let i_err_det[Strip(errors[1])] = Div1k(errors[2])
                let i_errors += errors[2]
            endif
        endif
    endfor
    return data
endfunction
