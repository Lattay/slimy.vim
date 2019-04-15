"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Configuration
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if !exists('g:slimy_preserve_curpos')
    let g:slimy_preserve_curpos = 1
end

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Neovim terminal
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if has('nvim')
    function! s:Split(cmd, vertical) abort
        let winid = win_getid()
        if a:vertical
            exec('vsplit new')
        else
            exec('split new')
        endif

        termopen(a:cmd)
        let id = bufnr('%')
        call win_gotoid(winid)

        return id
    endfunction

    function! s:Send(config, text)
        let bufnr = str2nr(get(a:config,'bufnr',''))
        let var = getbufinfo(bufnr)[0]['variables']
        if !has_key(var, 'terminal_job_id')
            echoerr 'Invalid terminal. Use :SlimyConfig to select a terminal'
            return
        endif
        let jobid = var['terminal_job_id']
        call chansend(str2nr(jobid), split(a:text, '\n', 1))
    endfunction

    function! TermBufList() abort
        let term_buf = []
        for buf in getbufinfo()
            if has_key(buf['variables'], 'terminal_job_id')
                call add(buf['bufnr'], i)
            endif
        endfor
        return term_buf
    endfunction


    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Vim terminal
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
else
    if !exists('*term_start')
        echoerr 'vimterminal support requires vim built with :terminal support'
    else
        function! s:Split(cmd, vertical) abort
            let winid = win_getid()
            let id = term_start(cmd, {'vertical': vertical})
            call win_gotoid(winid)
            return id
        endfunction

        function! s:Send(config, text)
            let bufnr = str2nr(get(a:config,'bufnr',''))
            if len(term_getstatus(bufnr))==0
                echoerr 'Invalid terminal. Use :SlimyConfig to select a terminal'
                return
            endif
            " Ideally we ought to be able to use a single term_sendkeys call however as
            " of vim 8.0.1203 doing so can cause terminal display issues for longer
            " selections of text.
            for l in split(a:text,'\n\zs')
                call term_sendkeys(bufnr,substitute(l,'\n','\r',''))
                call term_wait(bufnr)
            endfor
        endfunction

        function! s:TermBufList() abort
            return filter(term_list(),'term_getstatus(v:val)=~"running"')
        endfunction
    endif

endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:TerminalDescription(n, term) abort
    return a:n . '. ' . '#' . a:term['bufnr'] . a:term['name']
endfunction

function! s:SID() abort
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun

function! s:EscapeText(text) abort
    if exists('&filetype')
        let custom_escape = 'slimy#' . substitute(&filetype, '[.]', '_', 'g') . '_EscapeText'
        if exists('*' . custom_escape)
            let result = call(custom_escape, [a:text])
        end
    end

    " use a:text if the ftplugin didn't kick in
    if !exists('result')
        let result = a:text
    end

    " return an array, regardless
    if type(result) == type('')
        return [result]
    else
        return result
    end
endfunction

function! s:GetConfig() abort
    " b:slimy_config already configured...
    if exists('b:slimy_config')
        return
    end
    " assume defaults, if they exist
    if exists('g:slimy_default_config')
        let b:slimy_config = g:slimy_default_config
    end
    " skip confirmation, if configured
    if exists('g:slimy_dont_ask_default') && g:slimy_dont_ask_default
        return
    end

    if !exists('b:slimy_config')
        let b:slimy_config = {'termid': ''}
    end
    let terms = map(s:TermBufList(),'getbufinfo(v:val)[0]')
    let choices = map(copy(terms),'s:TerminalDescription(v:key+1,v:val)')
    call add(choices, printf('%2d. <New instance>',len(terms)+1))
    let choice = len(choices)>1
                \ ? inputlist(choices)
                \ : 1
    if choice > 0
        if choice > len(terms)
            if !exists('g:slimy_vimterminal_cmd')
                let cmd = input('Enter a command to run ['.&shell.']:')
                if len(cmd)==0
                    let cmd = &shell
                endif
            else
                let cmd = g:slimy_terminal_cmd
            endif
            if exists('g:slimy_terminal_config')
                let new_id = s:Split(cmd, g:slimy_terminal_config)
            else
                let new_id = s:Split(cmd)
            end
            let b:slimy_config['bufnr'] = new_id
        else
            let b:slimy_config['bufnr'] = terms[choice-1]['bufnr']
        endif
    endif
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

function! slimy#send_range(startline, endline) abort
    call s:GetConfig()

    let rv = getreg('"')
    let rt = getregtype('"')
    silent exe a:startline . ',' . a:endline . 'yank'
    call slimy#send(@")
    call setreg('"', rv, rt)
endfunction

function! slimy#send_lines(count) abort
    call s:GetConfig()

    let rv = getreg('"')
    let rt = getregtype('"')
    silent exe 'normal! ' . a:count . 'yy'
    call slimy#send(@")
    call setreg('"', rv, rt)
endfunction

function! slimy#store_curpos() abort
    if g:slimy_preserve_curpos == 1
        let has_getcurpos = exists('*getcurpos')
        if has_getcurpos
            " getcurpos() doesn't exist before 7.4.313.
            let s:cur = getcurpos()
        else
            let s:cur = getpos('.')
        endif
    endif
endfunction


function! slimy#send(text) abort
    call s:GetConfig()

    " this used to return a string, but some receivers (coffee-script)
    " will flush the rest of the buffer given a special sequence (ctrl-v)
    " so we, possibly, send many strings -- but probably just one
    let pieces = s:_EscapeText(a:text)
    for piece in pieces
        if type(piece) == 0  " a number
            if piece > 0  " sleep accepts only positive count
                execute 'sleep' piece . 'm'
            endif
        else
            call s:Send(b:slimy_config, piece)
        end
    endfor
endfunction

function! slimy#config() abort
    call inputsave()
    call s:Config()
    call inputrestore()
endfunction

