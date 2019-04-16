function! slimy#send#escape_text(text) abort
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

if has('nvim')
    function! slimy#send#send(config, text) abort
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
else
    if !exists('*term_start')
        echoerr 'vimterminal support requires vim built with :terminal support'
    endif

    function! slimy#send#send(config, text) abort
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
endif

