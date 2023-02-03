" This on is used as a opfunc
" :help opfunc
" type may be 'line', 'char' or 'block'
function! slimy#send_op(type) abort
  if !slimy#config#get_config()
    return
  endif

  call slimy#send(join(s:get_motion_lines(a:type ==# 'line'), "\n") . "\n")

  call s:RestoreCurPos()
endfunction

" This on is used only in visual mode
" :help opfunc
function! slimy#send_reg(linewise) abort
  if !slimy#config#get_config()
    return
  endif

  call slimy#send(join(s:get_visual(a:linewise), "\n") . "\n")

  call s:RestoreCurPos()
endfunction

function! slimy#send_range(startline, endline) abort
  if !slimy#config#get_config()
    return
  endif

  call slimy#send(join(getline(a:startline, a:endline), "\n") . "\n")
endfunction

function! slimy#send(text) abort
  if !slimy#config#get_config()
    return
  endif

  " this used to return a string, but some receivers (coffee-script)
  " will flush the rest of the buffer given a special sequence (ctrl-v)
  " so we, possibly, send many strings -- but probably just one
  let l:pieces = slimy#send#escape_text(a:text)
  for piece in l:pieces
    if type(piece) == type(0)
      if piece > 0  " sleep accepts only positive count
        execute 'sleep' l:piece . 'm'
      endif
    else
      call slimy#send#send(b:slimy_config, l:piece)
    endif
  endfor
endfunction

function! slimy#config() abort
  if exists('b:slimy_config')
    unlet b:slimy_config
  endif
  call inputsave()
  call slimy#config#config()
  call inputrestore()
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

function! s:RestoreCurPos() abort
  if g:slimy_preserve_curpos == 1 && exists('s:cur')
    call setpos('.', s:cur)
    unlet s:cur
  endif
endfunction

" https://stackoverflow.com/a/6271254 modified for motion
function! s:get_motion_lines(linewise)
  " Why is this not a built-in Vim script function?!
  let [l:line_start, l:column_start] = getpos("'[")[1:2]
  let [l:line_end, l:column_end] = getpos("']")[1:2]
  let l:lines = getline(l:line_start, l:line_end)
  if len(l:lines) == 0
    return ['']
  endif
  if !a:linewise
    let l:lines[-1] = l:lines[-1][: l:column_end - (&selection ==# 'inclusive' ? 1 : 2)]
    let l:lines[0] = l:lines[0][l:column_start - 1:]
  endif
  return l:lines
endfunction

function! s:get_visual(linewise)
  " Why is this not a built-in Vim script function?!
  let [l:line_start, l:column_start] = getpos("'<")[1:2]
  let [l:line_end, l:column_end] = getpos("'>")[1:2]
  let l:lines = getline(l:line_start, l:line_end)
  if len(l:lines) == 0
    return ['']
  endif
  if !a:linewise
    let l:lines[-1] = l:lines[-1][: l:column_end - (&selection ==# 'inclusive' ? 1 : 2)]
    let l:lines[0] = l:lines[0][l:column_start - 1:]
  endif
  return l:lines
endfunction
