if has('nvim')
  function! slimy#split#split(cmd, config) abort
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
else
  function! slimy#split#split(cmd, config) abort
    let l:winid = win_getid()
    let l:id = term_start(a:cmd, a:config)
    call win_gotoid(l:winid)
    return l:id
  endfunction
endif
