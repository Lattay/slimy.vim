"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Configuration
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if !exists('g:slimy_preserve_curpos')
    let g:slimy_preserve_curpos = 1
endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Neovim terminal
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if has('nvim')
    function! s:Split(cmd, config) abort
        let l:winid = win_getid()
        if has_key(a:config, 'vertical') && a:config['vertical']
            exec('vsplit new')
        else
            exec('split new')
        endif

        call termopen(a:cmd)
        let l:id = bufnr('%')
        call win_gotoid(l:winid)

        return l:id
    endfunction

    function! s:Send(config, text) abort
        let l:bufnr = str2nr(get(a:config,'bufnr',''))
        try
            let l:var = getbufinfo(bufnr)[0]['variables']
        catch
            echo 'Invalid terminal. Use :SlimyConfig to select a terminal'
            return
        endtry
        if !has_key(l:var, 'terminal_job_id')
            echo 'Invalid terminal. Use :SlimyConfig to select a terminal'
            return
        endif
        let l:jobid = l:var['terminal_job_id']
        call chansend(str2nr(l:jobid), split(a:text, '\n', 1))
    endfunction

    function! s:TermBufList() abort
        let l:term_buf = []
        for buf in getbufinfo()
            if has_key(buf['variables'], 'terminal_job_id')
                call add(l:term_buf, l:buf['bufnr'])
            endif
        endfor
        return l:term_buf
    endfunction

    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Vim terminal
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
else
    if !exists('*term_start')
        echoerr 'vimterminal support requires vim built with :terminal support'
    else
        function! s:Split(cmd, config) abort
            let l:winid = win_getid()
            let l:id = term_start(a:cmd, a:config)
            call win_gotoid(l:winid)
            return l:id
        endfunction

        function! s:Send(config, text) abort
            let l:bufnr = str2nr(get(a:config,'bufnr',''))
            if len(term_getstatus(l:bufnr))==0
                echo 'Invalid terminal. Use :SlimyConfig to select a terminal'
                return
            endif
            " Ideally we ought to be able to use a single term_sendkeys call however as
            " of vim 8.0.1203 doing so can cause terminal display issues for longer
            " selections of text.
            for l in split(a:text,'\n\zs')
                call term_sendkeys(l:bufnr,substitute(l,'\n','\r',''))
                call term_wait(l:bufnr)
            endfor
        endfunction

        function! s:TermBufList() abort
            return filter(term_list(),'term_getstatus(v:val) =~# "running"')
        endfunction
    endif

endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:TerminalDescription(n, term) abort
    return printf('%2d. %s',a:n, a:term['name'])
endfunction

function! s:SID() abort
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun

function! s:EscapeText(text) abort
    if exists('&filetype')
        let l:custom_escape = 'slimy#' . substitute(&filetype, '[.]', '_', 'g') . '_EscapeText'
        if exists('*' . l:custom_escape)
            let l:result = call(custom_escape, [a:text])
        endif
    endif

    " use a:text if the ftplugin didn't kick in
    if !exists('result')
        let l:result = a:text
    endif

    " return an array, regardless
    if type(l:result) == type('')
        return [l:result]
    else
        return l:result
    endif
endfunction

function! s:Config() abort
    if !exists('b:slimy_config')
        let b:slimy_config = {}
    endif
    let l:terms = map(s:TermBufList(),'getbufinfo(v:val)[0]')
    let l:choices = map(copy(l:terms),'s:TerminalDescription(v:key+1,v:val)')
    call add(choices, printf('%2d. <New instance>',len(terms)+1))
    let l:choice = len(l:choices) > 1 ? inputlist(l:choices) : 1
    if l:choice == 0
        return 0  " cancel
    else
        if l:choice <= len(l:terms)
            let b:slimy_config['bufnr'] = l:terms[l:choice-1]['bufnr']
        else
            if !exists('g:slimy_terminal_cmd')
                let l:cmd = input('Enter a command to run (type nothing to cancel): ')
                if len(l:cmd)==0
                    return 0  " cancel
                endif
                let b:slimy_config['cmd'] = l:cmd
            else
                let l:cmd = g:slimy_terminal_cmd
                let b:slimy_config['cmd'] = l:cmd
            endif
            if exists('g:slimy_terminal_config')
                let l:new_id = s:Split(l:cmd, g:slimy_terminal_config)
            else
                let l:new_id = s:Split(l:cmd, {})
            endif
            let b:slimy_config['bufnr'] = l:new_id
        endif
        return 1
    endif
endfunction

function! s:ConfigStillValid() abort
    if has_key(b:slimy_config, 'bufnr')
        if len(getbufinfo(b:slimy_config['bufnr'])) ==# 1
            return 1
        endif
    endif
    return 0
endfunction

function! s:RenewConfig() abort
    if has_key(b:slimy_config, 'cmd')
        if exists('g:slimy_terminal_config')
            let l:new_id = s:Split(b:slimy_config['cmd'], g:slimy_terminal_config)
        else
            let l:new_id = s:Split(b:slimy_config['cmd'], {})
        endif
        let b:slimy_config['bufnr'] = l:new_id
        return 1
    else
        return s:Config()
    endif
endfunction

function! s:GetConfig() abort
    " b:slimy_config already configured...
    if exists('b:slimy_config')
        if s:ConfigStillValid()
            return 1
        else
            return s:RenewConfig()
        endif
    endif
    " assume defaults, if they exist
    if exists('g:slimy_default_config')
        let b:slimy_config = g:slimy_default_config
    endif
    " skip confirmation, if configured
    if exists('g:slimy_dont_ask_default') && g:slimy_dont_ask_default
        return 1
    endif
    return s:Config()
endfunction

function! s:RestoreCurPos() abort
    if g:slimy_preserve_curpos == 1 && exists('s:cur')
        call setpos('.', s:cur)
        unlet s:cur
    endif
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Public interface
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! slimy#send_op(type, ...) abort
    if !s:GetConfig()
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
    if !s:GetConfig()
        return
    endif

    let l:rv = getreg('"')
    let l:rt = getregtype('"')
    silent exe a:startline . ',' . a:endline . 'yank'
    call slimy#send(@")
    call setreg('"', l:rv, l:rt)
endfunction

function! slimy#send_lines(count) abort
    if !s:GetConfig()
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
    if !s:GetConfig()
        return
    endif

    " this used to return a string, but some receivers (coffee-script)
    " will flush the rest of the buffer given a special sequence (ctrl-v)
    " so we, possibly, send many strings -- but probably just one
    let l:pieces = s:EscapeText(a:text)
    for piece in pieces
        if type(piece) == 0  " a number
            if piece > 0  " sleep accepts only positive count
                execute 'sleep' l:piece . 'm'
            endif
        else
            call s:Send(b:slimy_config, l:piece)
        endif
    endfor
endfunction

function! slimy#config() abort
    call inputsave()
    call s:Config()
    call inputrestore()
endfunction

