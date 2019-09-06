function! Tab2diff(tabnbr)
    let tabnbr1 = tabpagenr()
    let bufnbr = tabpagebuflist(a:tabnbr)[0]
    execute ":vertical sbuffer " . bufnbr
    execute "normal \<c-w>r"
    execute "diffthis"
    execute "normal \<c-w>w"
    execute "diffthis" 
endfunction

function! DiffSect(tabnbr)
    let foldl = foldlevel(line("."))
    let tabnbr1 = tabpagenr()
    let sc = 0
    if  foldl > 0 
        execute 'normal! zv'
        execute "normal! ]z"
        let end = line(".")
        execute "normal! [z"
        let start = line(".")
        let slnbr = start + 1
        let searchl = getline(slnbr)
        if searchl !~  '\v\C.*Command'
            let slnbr = start
            let searchl = getline(slnbr)
        endif
"       let searchl = substitute(escape(searchl, '/\.*$^~['), '\_s\+', '\\_s\\+', 'g')
        let searchl = '^' . escape(searchl, '/\.*$^~[''') . '$'
        let sc = 1
        execute "normal! gg"
        while 1
            let ln = search(searchl,"W")
            if ln == slnbr
                break
            elseif ln == 0 || ln > slnbr
                echoe "Search line '" . searchl . "' not found: " . ln
                return
            else
                let sc += 1
            endif                
        endwhile
    else
        let start = 1
        let end = "$"
    endif
    let lines1=getline(start,end)
    execute 'normal! ' . a:tabnbr . 'gt'
    if sc > 0
        execute "normal! gg"
        for i in range(1, sc)
            let ln = search(searchl, "W")
        endfor
        if ln == 0
            echoe "Search line '" . searchl . "' not found in file 2"
            return
        endif                
        execute 'normal! zv'
        execute "normal! ]z"
        let end = line(".")
        execute "normal! [z"
        let start = line(".")
    endif
    let lines2 = getline(start,end)
    exe ":tabnew"
    silent file DiffSect1
    call append(line("$"), lines1)
    execute "vnew"
    silent file DiffSect2
    call append(line("$"), lines2)
    execute "normal \<c-w>r"
    execute "diffthis"
    execute "normal \<c-w>w"
    execute "diffthis" 
endfunction


function! DiffNbr(tabnbr)
    let regex = @/
    let foldl = foldlevel(line("."))
    let tabnbr1 = tabpagenr()
    let sc = 0
    if  foldl > 0 
        execute 'normal! zv'
        execute "normal! ]z"
        let end = line(".")
        execute "normal! [z"
        let start = line(".")
        let slnbr = start + 1
        let searchl = getline(slnbr)
        if searchl !~  '\v\C.*Command'
            let slnbr = start
            let searchl = getline(slnbr)
        endif
        let searchl = '^' . escape(searchl, '/\.*$^~[''') . '$'
        let sc = 1
        execute "normal! gg"
        while 1
            let ln = search(searchl,"W")
            if ln == slnbr
                break
            elseif ln == 0 || ln > slnbr
                echoe "Search line '" . searchl . "' not found: " . ln
                return
            else
                let sc += 1
            endif                
        endwhile
    else
        let start = 1
        let end = "$"
    endif
    let lines1=getline(start,end)
    execute 'normal! ' . a:tabnbr . 'gt'
    if sc > 0
        execute "normal! gg"
        for i in range(1, sc)
            let ln = search(searchl, "W")
        endfor
        if ln == 0
            echoe "Search line '" . searchl . "' not found in file 2"
            return
        endif                
        execute 'normal! zv'
        execute "normal! ]z"
        let end = line(".")
        execute "normal! [z"
        let start = line(".")
    endif
    let lines2 = getline(start,end)

    let data = {}
    let regex_res = []
    let line_nbr = 0
    for line in lines1
        if line =~ regex
            let regex_res = matchlist(line, regex)
            let index = 1
            let numbers = []
            let key = ""
            while index < len(regex_res)
                if regex_res[index] =~ '\v^\d+$'
                    let numbers += [Div1m(regex_res[index])]
                else
                    let key = key . regex_res[index]
                endif
                let index += 1
            endwhile
            let data[line_nbr] =  [regex_res[0]] + numbers
        endif
        let line_nbr += 1
    endfor
    let line_nbr = 0
    for line in lines2
        if line =~ regex
            let regex_res = matchlist(line, regex)
            let index = 1
            let numbers = []
            let numbers_div1m = []
            let key = ""
            while index < len(regex_res)
                if regex_res[index] =~ '\v^\d+$'
                    let numbers += [regex_res[index]]
                    let numbers_div1m += [Div1m(regex_res[index])]
                else
                    let key = key . regex_res[index]
                endif
                let index += 1
            endwhile
            let index = 0
            while index < len(numbers)
                let diff = numbers_div1m[index] - data[line_nbr][index+1]
                let line = substitute(line, numbers[index], printf("%-" . strlen(numbers[index]) . "s", Mul1m(diff)), "")
                let index +=1
            endwhile
            let lines2[line_nbr] = line
        endif
        let line_nbr += 1
    endfor
    call NewTab("DiffNbr")
    call append(line("$"), lines2)

"   for result in values(data)
"       call append(line("$"), result[0])
"   endfor
endfunction

function! DiffMarks()
    let start = line("'a")
    let end = line("'b")
    let lines1=getline(start,end)
    let start = line("'c")
    let end = line("'d")
    let lines2 = getline(start,end)
    exe ":tabnew"
    call append(line("$"), lines1)
    execute "vnew"
    call append(line("$"), lines2)
    execute "normal \<c-w>r"
    execute "diffthis"
    execute "normal \<c-w>w"
    execute "diffthis" 
endfunction
