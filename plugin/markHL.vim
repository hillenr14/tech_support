"  Name        - markHL.vim
"  Description - Vim simple global plugin for easy line marking and jumping
"  Last Change - 8 Jan 2011
"  Creator     - Nacho <pkbrister@gmail.com>
"
"  Inspired by Kate 'bookmarks' and other scripts herein, I devised a convenient way to mark lines and highlight mark lines.
"  The idea is to mark lines and then jump from one to the other, in an easier way than the one Vim provides.
"  Lines with markers are highlighted, which is convenient to visually spot where the mark is. 
"  One does not need to remember which markers are already in use and which are free anymore, just add marks and remove 
"  marks, and the script will manage where to store them or free them.
"  
"  USAGE:
"  <F1>		Turn on highlighting for all lines with markers on them
"  <F2>		Turn off the highlighting for marked lines
"  <SHIFT-F2>	Erase all markers [a-z]
"  <F5>		Add a mark on the current line (and highlight)
"  <SHIFT-F5>	Remove the mark on the current line
"
"  Then, just jump from one mark to the next using the classic [' and ]' jumps
"  
"  Try it! it's nice!
"  
"  NOTE:
"  Of course, the highlight group I define ("Marks") should be tweaked to one's taste, 
"
"  and the same applies to the keyboard mappings.
"  
"  NOTE-UPDATE:
"  The classic marking method (ie. typing 'ma', 'mb', 'mc'...) can be used in
"  combination with this one, but one has to be careful not to overwrite an
"  existing mark. Check with the :marks command. HINT: the code marks from the
"  'a' to the 'z', so if there are not too many marks, one can safely assume
"  that the last ones ('z 'x 'y 'w ...) are safe to use.
"
"  Enjoy...

"highlight Marks term=reverse ctermfg=0 ctermbg=40 guibg=LightCyan

function! HLMarks(group)
    call clearmatches()
    let index = char2nr('a')
    while index < char2nr('z')
        call matchadd( a:group, '\%'.line( "'".nr2char(index)).'l')
        let index = index + 1
    endwhile
endfunction


function! AddHLMark(group)
    let index = char2nr('a')
    while getpos("'".nr2char(index))[2] != 0
        let index = index + 1
    endwhile
    if index != char2nr('z')
        exe 'normal m'.nr2char(index)
        call HLMarks(a:group)
    endif
endfunction


function! DelHLMark(group)
    let index = char2nr('a')
    let deleted = 0
    while index < char2nr('z')
        if line(".") == line("'".nr2char(index))
            exe 'delmarks '.nr2char(index)
            call HLMarks(a:group)
            let index = char2nr('z')
            let deleted = 1
        endif
        let index = index + 1
    endwhile
    return deleted
endfunction

function! ToggleHLMark(group)
    if !DelHLMark(a:group)
        call AddHLMark(a:group)
    endif
endfunction

function! Compare(i1, i2)
	return a:i1 == a:i2 ? 0 : a:i1 > a:i2 ? 1 : -1
endfunc

function! NextMark(dir)
    let index = char2nr('a')
    let m_lines = []
    while index < char2nr('z')
        let m_line = line("'".nr2char(index))
        if m_line > 0
            let m_lines += [m_line]
        endif
        let index = index + 1
    endwhile
    if len(m_lines) == 0 | return | endif
    let m_lines = sort(m_lines, "Compare")
    let line = line(".")
    exe 'echo'
    if line <= m_lines[0] &&  a:dir == "["
        call setpos(".", [0,m_lines[-1],0,0])
        exe 'redraw | echo "search hit TOP, continuing at BOTTOM"'
    elseif line >= m_lines[-1] &&  a:dir == "]"
        call setpos(".", [0,m_lines[0],0,0])
        exe 'redraw | echo "search hit BOTTOM, continuing at TOP"'
    else
        exe 'normal! ' . a:dir . ''''
    endif
    if foldlevel(line(".")) > 0 
        exe 'normal! zO'
    endif
endfunction

"nmap <silent> <F1> :call HLMarks("Marks")<CR>
"nmap <silent> <F2> :call clearmatches()<CR>
"nmap <silent> <S-F2> :call clearmatches()\|:delmarks a-z<CR>
"nmap <silent> <F5> :call AddHLMark("Marks")<CR>
"nmap <silent> <S-F5> :call DelHLMark("Marks")<CR>
noremap <silent> m<leader> :call ToggleHLMark("DiffText")<CR>
noremap <silent> ]' :call NextMark("]")<CR>
noremap <silent> [' :call NextMark("[")<CR>

