function! IndentLevel(lnum)
    let leading_spaces = indent(a:lnum) % &shiftwidth
    let indentl = (indent(a:lnum) - leading_spaces) / &shiftwidth - 1
    if indentl < 0
        let indentl = 0
    endif
    let line = getline(a:lnum)
    if line =~ '\v^\s*exit\s*$'
        let indentl += 1
        return indentl
    endif
    if line =~? '\v(^(  )?echo )|(^(  )?#---)|^\s*$'
        let indentl = -1
    endif
    return indentl 
endfunction


function! NextNonCommentLine(lnum, dir)
    let numlines = line('$')
    let current = a:lnum + a:dir

    while current <= numlines && current >= 1
        if getline(current) !~? '\v(^(  )?echo )|(^(  )?#---)|^\s*$'
            return current
        endif

        let current += a:dir
    endwhile

    return -2
endfunction



function! GetCfgFold(lnum)
    if getline(a:lnum) =~? '\v^\s*$'
        return '-1'
    endif

    let this_indent = IndentLevel(a:lnum) 
    let next_indent = IndentLevel(NextNonCommentLine(a:lnum, 1))
"   let prev_indent = IndentLevel(NextNonCommentLine(a:lnum, -1))

"   if this_indent < prev_indent
"       return prev_indent
    if this_indent == -1
        return '-1'
    elseif next_indent <= this_indent
        return this_indent
    elseif next_indent > this_indent
        return '>' . next_indent
    endif
endfunction

function! CfgFold()
    call cursor(1, 1)
    let start = search('CLI Command: ''admin display-config''', "W")
    if start == 0
        setlocal foldexpr=GetCfgFold(v:lnum)
        setlocal foldmethod=expr
        setlocal foldtext=CfgFoldText()
        return
    endif
    let start += 1
    call search('exit all', "W")
    let end = search('exit all', "W")
    let lines = getline(start,end)
    call NewTab("CfgFold")
    call append(line("$"), lines)
    setlocal foldexpr=GetCfgFold(v:lnum)
    setlocal foldmethod=expr
    setlocal foldtext=CfgFoldText()
endfunction


function! CfgFoldText()
    let line = getline(v:foldstart)
    let indent = indent(v:foldstart) - 4
    let line = substitute(line, '\v^\s*(.{-})\s*$', '\1', '')
    let line1 = getline(v:foldstart+1)
    if line1 =~  '\v\C^\s*description '
        let line1 = substitute(line1, '\v\s*description (".*")', '\1', '')
        let line = line . " - " . line1
    endif
    return printf("%4d" ,v:foldend - v:foldstart + 1) . printf("%-" . indent . "s", ":") . line
endfunction
