function! Buf2Tab()
    let buf_list = []
    for buf_nr in range(1, bufnr("$"))
        if buflisted(buf_nr)
            call extend(buf_list, [buf_nr])
        endif
    endfor
    let open_buf_list = []
    for tab_nr in range(1, tabpagenr("$"))
        call extend(open_buf_list, tabpagebuflist(tab_nr))
    endfor
    call filter(buf_list, 'count(open_buf_list, v:val)==0')    
    for buf_nr in buf_list
        execute 'tabnew'
        execute 'buffer ' . buf_nr
    endfor
endfunction

noremap <leader>bt :call Buf2Tab()<cr>
noremap <leader>bd :bd<cr>
