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
    function! s:TermSplit(cmd, vertical) abort
        if a:vertical
            exec('vsplit term://' . a:cmd)
        else
            exec('split term://' . a:cmd)
        endif
        let l:id = b:terminal_job_id
        wincmd w
        return l:id
    endfunction

    function! s:Send(config, text)
        " Neovim jobsend is fully asynchronous, it causes some problems with
        " iPython %cpaste (input buffering: not all lines sent over)
        " So this s:WritePasteFile can help as a small lock & delay
        call s:WritePasteFile(a:text)
        call chansend(str2nr(a:config['jobid']), split(a:text, '\n', 1))
    endfunction

    function! s:Config() abort
        if exists('b:slimy_config')
            let l:default = b:slimy_config['jobid']
        else
            let b:slimy_config = {'jobid': '3'}
            let l:default = ''
        end

        let l:res = input('existing term (type the job id) or new split (type v or s) ? ', l:default)

        if l:res ==# 'v' || l:res ==# 's'
            " ask for the command and create the split
            let l:cmd = input('command to launch the repl: ')
            let l:id = s:NeovimTermSplit(l:cmd, l:res ==# 'v')
            echom 'New terminal have job id ' . l:id
            let b:slimy_config['jobid'] = l:id
        else
            let b:slimy_config['jobid'] = l:res
        end
    endfunction
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Vim terminal
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
else
    function! s:Split(cmd, vertical) abort
        return term_start(cmd, {'vertical': vertical})
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

    function! s:Config() abort
        if !exists('*term_start')
            echoerr 'vimterminal support requires vim built with :terminal support'
            return
        endif
        if !exists('b:slimy_config')
            let b:slimy_config = {'bufnr': ''}
        end
        let bufs = filter(term_list(),'term_getstatus(v:val)=~"running"')
        let terms = map(bufs,'getbufinfo(v:val)[0]')
        let choices = map(copy(terms),'s:VimterminalDescription(v:key+1,v:val)')
        call add(choices, printf('%2d. <New instance>',len(terms)+1))
        let choice = len(choices)>1
                    \ ? inputlist(choices)
                    \ : 1
        if choice > 0
            if choice>len(terms)
                if !exists('g:slimy_vimterminal_cmd')
                    let cmd = input('Enter a command to run ['.&shell.']:')
                    if len(cmd)==0
                        let cmd = &shell
                    endif
                else
                    let cmd = g:slimy_vimterminal_cmd
                endif
                let winid = win_getid()
                if exists('g:slimy_vimterminal_config')
                    let new_bufnr = term_start(cmd, g:slimy_vimterminal_config)
                else
                    let new_bufnr = term_start(cmd)
                end
                call win_gotoid(winid)
                let b:slimy_config['bufnr'] = new_bufnr
            else
                let b:slimy_config['bufnr'] = terms[choice-1].bufnr
            endif
        endif
    endfunction
endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:SID()
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun

function! s:WritePasteFile(text)
    " could check exists("*writefile")
    call system('cat > ' . g:slimy_paste_file, a:text)
endfunction

function! s:EscapeText(text)
    if exists('&filetype')
        let custom_escape = 'slimy#' . substitute(&filetype, '[.]', '_', 'g') . '#EscapeText'
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

function! s:GetConfig()
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
    " prompt user
    call s:SlimyDispatch('Config')
endfunction

function! s:SlimyRestoreCurPos()
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

function! slimy#store_curpos()
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


function! slimy#send(text)
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

