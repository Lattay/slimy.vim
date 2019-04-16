"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Configuration
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if !exists('g:slimy_preserve_curpos')
    let g:slimy_preserve_curpos = 1
endif

" Private helpers

if has('nvim')
    function! s:TermBufList() abort
        let l:term_buf = []
        for buf in getbufinfo()
            if has_key(buf['variables'], 'terminal_job_id')
                call add(l:term_buf, l:buf['bufnr'])
            endif
        endfor
        return l:term_buf
    endfunction
else
    function! s:TermBufList() abort
        return filter(term_list(),'term_getstatus(v:val) =~# "running"')
    endfunction
endif

function! s:TerminalDescription(n, term) abort
    return printf('%2d. %s',a:n, a:term['name'])
endfunction

function! s:ConfigStillValid() abort
    if has_key(b:slimy_config, 'bufnr')
        if len(getbufinfo(b:slimy_config['bufnr'])) ==# 1
            return 1
        endif
    endif
    return 0
endfunction

" Public interface

function! slimy#config#config() abort
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
            if !has_key(b:slimy_config, 'cmd')
                let l:cmd = input('Enter a command to run (type nothing to cancel): ')
                if len(l:cmd)==0
                    return 0  " cancel
                endif
                let b:slimy_config['cmd'] = l:cmd
            elseif (!exists('b:slimy_confirm_cmd') || !b:slimy_confirm_cmd)
            \      && (!exists('g:slimy_confirm_cmd') || !g:slimy_confirm_cmd)
                let l:cmd = input('Enter a command to run (type nothing to cancel): ', b:slimy_config['cmd'])
                if len(l:cmd)==0
                    return 0  " cancel
                endif
                let b:slimy_config['cmd'] = l:cmd
            else
                let l:cmd = b:slimy_config['cmd']
                let b:slimy_config['cmd'] = l:cmd
            endif
            if exists('b:slimy_terminal_config')
                let l:new_id = slimy#split#split(l:cmd, b:slimy_terminal_config)
            elseif  exists('g:slimy_terminal_config')
                let l:new_id = slimy#split#split(l:cmd, g:slimy_terminal_config)
            else
                let l:new_id = slimy#split#split(l:cmd, {})
            endif
            let b:slimy_config['bufnr'] = l:new_id
        endif
        return 1
    endif
endfunction

function! slimy#config#get_config() abort
    " b:slimy_config already configured...
    if exists('b:slimy_config')
        if s:ConfigStillValid()
            return 1
        endif
    endif
    " assume defaults, if they exist
    if exists('g:slimy_default_config')
        let b:slimy_config = g:slimy_default_config
    endif
    return slimy#config#config()
endfunction
