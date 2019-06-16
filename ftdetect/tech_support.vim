" execute 'echom "sourcing " . expand("%")'
au BufNewFile,BufRead *			call s:Check_inp()
func! s:Check_inp()
    let first_line = getline(1)
    if first_line =~ '^Information as of '
        set filetype=tech_sup
    endif
endfunc

