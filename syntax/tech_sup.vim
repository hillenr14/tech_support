if exists("b:current_syntax")
    finish
endif

"execute 'echom "sourcing " . expand("%")'
" syntax keyword tsKeyword Command
" highlight link tsKeyword Keyword

highlight Marks term=reverse ctermfg=0 ctermbg=40 guibg=LightCyan
call HLMarks("Marks")
syntax match tsCommand "\vCommand.*'.*'"
highlight link tsCommand Function

if exists("b:current_folding")
    finish
endif


function! MyFoldText()
    let line = getline(v:foldstart+1)
    if line =~  '\v\C.*Command'
        if line =~ '\v^[0-9]{1,2}:|^[A,B,C,D]:|^[0-9]{1,2}\/[0-9]:|^..cpu2:'
            let card = substitute(line, ':.*', ': ', '')
        else
            let card = ""
        endif
        let sub = card . substitute(line, '^[^'']*', '', '')
    else
        let sub = getline(v:foldstart)
        if sub =~ '\v^([0-9,A,B,C,D]{1,2}: )?  tmd: '
            let sublen = strlen(sub)
            let sub = matchlist(sub, '\v  tmd: (.*$)')[1]
            let len_dif = sublen - strlen(sub) - 2
            return printf("%" . len_dif . "d" ,v:foldend - v:foldstart + 1) . ": " . sub
        endif
    endif
    return v:folddashes . printf("%6d" ,v:foldend - v:foldstart + 1) . " - " . sub
endfunction

let command_pat = 'Command.*''.*'''
let group_id = "no_group"
let group_id_prev = "no_group"
let &foldmethod='manual'
let line = search(command_pat, "W")
let linestr = getline(line)
while line > 0
    if  linestr =~ '\v(''dhw_data'')|(''dtech_support'')|(''dhw_snapshot'')'
        execute "normal! mzj"
        let section_end = search(command_pat, "Wn") - 1
        let slot = matchstr(linestr, '\v^\d{1,2}')
        let icommand_pat = '\v\c(slot ' . slot . ')|(complex ' . slot . ')'
        let iline =  search(icommand_pat, 'W', section_end)
        while iline > 0
            execute "normal! jV"
            while 1 
                let iline =  search(icommand_pat, "W", section_end)
                if getline(iline - 1) =~ '\v\={20,}' || iline == 0
                    break
                endif
            endwhile
            if iline == 0
                execute "normal! " . section_end . "G"
            endif
            execute "normal! kokzfzCj"
        endwhile
        execute "normal! 'z"
        execute "delmarks z"
    endif
    if  linestr =~ '\v''tmd'''
        execute "normal! mzj"
        let section_end = search(command_pat, "Wn") - 1
        let icommand_pat = '\v(^([0-9,A,B,C,D]{1,2}(\/[12])?: )?  tmd: [\[|]\d+( [sdhm])? \d{2}[/:]\d{2}[/:]\d{2})|(\*\*\* Timos Crash Dump)'
        let iline =  search('\v^([0-9,A,B,C,D]{1,2}(\/[12])?: )?  tmd: .*\S{3,}', 'W', section_end)
        while iline > 0
            if getline(iline) =~ '\vTimos Crash Dump'
                let isection_end = search('\v(End of Crash Dump)|(Timos Crash Dump End)|(System Boot - Trace Buffer Initialized)', "Wn", section_end)
                if isection_end > 0
                    execute "normal! myj"
                    let iicommand_pat = '\v^([0-9,A,B,C,D]{1,2}(\/[12])?: )?  tmd: \[[^@]*\]$'
                    let iiline =  search(iicommand_pat, 'W', isection_end)
                    while iiline > 0
                        execute "normal! V"
                        let iiline =  search(iicommand_pat, "W", isection_end)
                        if iiline == 0
                            execute "normal! " . isection_end . "G"
                        endif
                        execute "normal! kzfzCj"
                    endwhile 
                    execute "normal! 'y"
                    execute "delmarks y"
                    execute "normal! V"
                    execute "normal! " . isection_end . "G"
                    execute "normal! zfzCj"
                    let iline =  search(icommand_pat, 'W', section_end)
                endif
            endif
            execute "normal! V"
            let pline = iline
            let iline =  search(icommand_pat, "W", section_end)
            if iline == 0
                execute "normal! " . section_end . "G"
            endif
            if iline - pline > 1 || iline == 0
                execute "normal! kzfzCj"
            else
                execute "normal! V"
            endif
        endwhile
        execute "normal! 'z"
        execute "delmarks z"
    endif
    execute "normal! jV"
    let line = search(command_pat, "W")
    let linestr = getline(line)
    if line == 0
        execute "normal! G"
    endif
    execute "normal! 2ko2kzfzC2j"
    if  linestr =~ '\v(show|tools dump) router [0-9]'
        let group_id = substitute(linestr, '\v\D*(\d+).*', '\1', 'g') "router id
    elseif  linestr =~ '\vshow port [1-9]'
        let group_id = "int_detail"
    else
        let group_id = "no_group" 
    endif
    if  group_id != group_id_prev
        if group_id_prev == "no_group"
            execute "normal! mz"
        else
            execute "normal! 2kV'zzfzC2j"
            execute "delmarks z"
            if group_id != "no_group"
                execute "normal! mz"
            endif    
        endif
        let group_id_prev = group_id
    endif
endwhile
execute "normal! gg"

setlocal foldtext=MyFoldText()

 
let b:current_syntax = "tech_support"
let b:current_folding = "tech_support"
