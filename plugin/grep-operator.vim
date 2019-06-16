nnoremap <leader>g :set operatorfunc=<SID>GrepOperator<cr>g@
vnoremap <leader>g :<c-u>call <SID>GrepOperator(visualmode())<cr>
nnoremap <leader>q :call QuickfixToggle()<cr>
command! -nargs=* Gr :call GrepInt([<f-args>])

function! GrepInt1(args)
    ec len(a:args)
endfunction

function! s:GrepOperator(type)
    let saved_unnamed_register = @@
    if a:type ==# 'v'
        execute "normal! `<v`>y"
    elseif a:type ==# 'char'
        execute "normal! `[v`]y"
    else
        return
    endif
    let @/ = @@
    silent execute ":grep! " . shellescape(@@) . " '%'"
    copen

    let @@ = saved_unnamed_register

endfunction


let g:quickfix_is_open = 0

function! QuickfixToggle()
    if g:quickfix_is_open
        lclose
        let g:quickfix_is_open = 0
        execute g:quickfix_return_to_window . "wincmd w"
    else
        let g:quickfix_return_to_window = winnr()
        lopen
        let g:quickfix_is_open = 1
    endif
endfunction

function! GrepInt(args_l)
    let l:search_str = @/
    let l:errorformat = &errorformat
    set errorformat=%f:%l:%m 
    call setloclist(0,[])
    let cur_pos = getpos(".")
    call setpos(".", [0, 1, 1, 0]) 
    let line = search(l:search_str, "We")
    while line > 0
        if len(a:args_l) == 0
            let lines = [0]
        else
            let lines = []
            for arg_s in a:args_l
                if arg_s =~ '\v^-?\d+-\d+$'
                    let nrs = matchlist(arg_s, '\v^(-?\d+)-(\d+)$')
                    let lines += range(nrs[1], nrs[2])
                elseif arg_s =~ '\v^-?\d+$'
                    let lines += [arg_s]
                endif
            endfor
        end
        let lines = sort(lines, "Compare")
        for line_nr in lines
            laddexpr expand("%") . ":" . (line + line_nr) .  ":" . getline(line + line_nr) . " "
        endfor
        let line = search(l:search_str, "We")
"       ec getpos(".")
    endwhile
    call setpos(".", cur_pos) 
    lopen
    let g:quickfix_is_open = 1
    let g:quickfix_return_to_window = winnr()
    let &errorformat = l:errorformat
endfunction


function! GrepDeb(...)
    let l:search_str = @/
    let l:errorformat = &errorformat
    set errorformat=%f:%l:%m 
    call setloclist(0,[])
    let cur_pos = getpos(".")
    call setpos(".", [0, 1, 1, 0]) 
    let line = search(l:search_str, "We")
    while line > 0
        let line_s = search('\v^\s*$', "bW")
        let lines = [line_s+1]
        if a:0 == 1
            for idx in range(0,a:1)
                if idx == 1 | continue | endif
                let lines += [line_s + (idx)]
            endfor
        end
        let lines = sort(lines, "Compare")
        for line_s in lines
            laddexpr expand("%") . ":" . line_s .  ":" . getline(line_s) . " "
        endfor
        call cursor(line+1, 1)
        let line = search(l:search_str, "W")
    endwhile
    call setpos(".", cur_pos) 
    lopen
    let g:quickfix_is_open = 1
    let &errorformat = l:errorformat
endfunction
