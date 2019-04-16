function! s:RestoreCurPos() abort
    if g:slimy_preserve_curpos == 1 && exists('s:cur')
        call setpos('.', s:cur)
        unlet s:cur
    endif
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Public interface
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" This on is used as a opfunc
function! slimy#send_op(type, ...) abort
    if !slimy#config#get_config()
        return
    endif

    let l:sel_save = &selection
    let &selection = 'inclusive'
    let l:rv = getreg('"')
    let l:rt = getregtype('"')

    if a:0  " Invoked from Visual mode, use '< and '> marks.
        silent exe 'normal! `<' . a:type . '`>y'
    elseif a:type ==# 'line'
        silent exe "normal! '[V']y"
    elseif a:type ==# 'block'
        silent exe "normal! `[\<C-V>`]\y"
    else
        silent exe 'normal! `[v`]y'
    endif

    call setreg('"', @", 'V')
    call slimy#send(@")

    let &selection = l:sel_save
    call setreg('"', l:rv, l:rt)

    call s:RestoreCurPos()
endfunction

function! slimy#send_range(startline, endline) abort
    if !slimy#config#get_config()
        return
    endif

    let l:rv = getreg('"')
    let l:rt = getregtype('"')
    silent exe a:startline . ',' . a:endline . 'yank'
    call slimy#send(@")
    call setreg('"', l:rv, l:rt)
endfunction

function! slimy#send_lines(count) abort
    if !slimy#config#get_config()
        return
    endif

    let l:rv = getreg('"')
    let l:rt = getregtype('"')
    silent exe 'normal! ' . a:count . 'yy'
    call slimy#send(@")
    call setreg('"', rv, rt)
endfunction

function! slimy#store_curpos() abort
    if g:slimy_preserve_curpos == 1
        let l:has_getcurpos = exists('*getcurpos')
        if l:has_getcurpos
            " getcurpos() doesn't exist before 7.4.313.
            let s:cur = getcurpos()
        else
            let s:cur = getpos('.')
        endif
    endif
endfunction

function! slimy#send(text) abort
    if !slimy#config#get_config()
        return
    endif

    " this used to return a string, but some receivers (coffee-script)
    " will flush the rest of the buffer given a special sequence (ctrl-v)
    " so we, possibly, send many strings -- but probably just one
    let l:pieces = slimy#send#escape_text(a:text)
    for piece in pieces
        if type(piece) == 0  " a number
            if piece > 0  " sleep accepts only positive count
                execute 'sleep' l:piece . 'm'
            endif
        else
            call slimy#send#send(b:slimy_config, l:piece)
        endif
    endfor
endfunction

function! slimy#config() abort
    unlet b:slimy_config
    call inputsave()
    call slimy#config#config()
    call inputrestore()
endfunction

