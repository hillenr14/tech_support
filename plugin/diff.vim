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
