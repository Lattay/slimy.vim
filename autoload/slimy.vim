"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Configuration
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if !exists("g:slimy_preserve_curpos")
  let g:slimy_preserve_curpos = 1
end

function! s:TermSplit(cmd, vertical) abort
    if a:vertical
        exec("vsplit term://" . a:cmd)
    else
        exec("split term://" . a:cmd)
    endif
    let l:id = b:terminal_job_id
    wincmd w
    return l:id
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Neovim terminal
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:NeovimSend(config, text)
  " Neovim jobsend is fully asynchronous, it causes some problems with
  " iPython %cpaste (input buffering: not all lines sent over)
  " So this s:WritePasteFile can help as a small lock & delay
  call s:WritePasteFile(a:text)
  call chansend(str2nr(a:config["jobid"]), split(a:text, "\n", 1))
endfunction

function! s:NeovimConfig() abort
  if exists("b:slimy_config")
    let l:default = b:slimy_config["jobid"]
  else
    let b:slimy_config = {"jobid": "3"}
    let l:default = ""
  end

  let l:res = input("existing term (type the job id) or new split (type v or s) ? ", l:default)

  if l:res ==# 'v' || l:res ==# 's'
      " ask for the command and create the split
      let l:cmd = input("command to launch the repl: ")
      let l:id = s:NeovimTermSplit(l:cmd, l:res ==# 'v')
      echom "New terminal have job id " . l:id
      let b:slimy_config["jobid"] = l:id
  else
    let b:slimy_config["jobid"] = l:res
  end
endfunction


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Vim terminal
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:VimSend(config, text)
  let bufnr = str2nr(get(a:config,"bufnr",""))
  if len(term_getstatus(bufnr))==0
    echoerr "Invalid terminal. Use :SlimyConfig to select a terminal"
    return
  endif
  " Ideally we ought to be able to use a single term_sendkeys call however as
  " of vim 8.0.1203 doing so can cause terminal display issues for longer
  " selections of text.
  for l in split(a:text,'\n\zs')
    call term_sendkeys(bufnr,substitute(l,'\n',"\r",''))
    call term_wait(bufnr)
  endfor
endfunction

function! s:VimterminalDescription(idx,info)
  let title = term_gettitle(a:info.bufnr)
  if len(title)==0
    let title = term_getstatus(a:info.bufnr)
  endif
  return printf("%2d.%4d %s [%s]",a:idx,a:info.bufnr,a:info.name,title)
endfunction

function! s:VimterminalConfig() abort
  if !exists("*term_start")
    echoerr "vimterminal support requires vim built with :terminal support"
    return
  endif
  if !exists("b:slimy_config")
    let b:slimy_config = {"bufnr": ""}
  end
  let bufs = filter(term_list(),"term_getstatus(v:val)=~'running'")
  let terms = map(bufs,"getbufinfo(v:val)[0]")
  let choices = map(copy(terms),"s:VimterminalDescription(v:key+1,v:val)")
  call add(choices, printf("%2d. <New instance>",len(terms)+1))
  let choice = len(choices)>1
        \ ? inputlist(choices)
        \ : 1
  if choice > 0
    if choice>len(terms)
      if !exists("g:slimy_vimterminal_cmd")
          let cmd = input("Enter a command to run [".&shell."]:")
          if len(cmd)==0
            let cmd = &shell
          endif
      else
          let cmd = g:slimy_vimterminal_cmd
      endif
      let winid = win_getid()
      if exists("g:slimy_vimterminal_config")
        let new_bufnr = term_start(cmd, g:slimy_vimterminal_config)
      else
        let new_bufnr = term_start(cmd)
      end
      call win_gotoid(winid)
      let b:slimy_config["bufnr"] = new_bufnr
    else
      let b:slimy_config["bufnr"] = terms[choice-1].bufnr
    endif
  endif
endfunction



"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:SID()
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun

function! s:WritePasteFile(text)
  " could check exists("*writefile")
  call system("cat > " . g:slimy_paste_file, a:text)
endfunction

function! s:_EscapeText(text)
  if exists("&filetype")
    let custom_escape = "_EscapeText_" . substitute(&filetype, "[.]", "_", "g")
    if exists("*" . custom_escape)
      let result = call(custom_escape, [a:text])
    end
  end

  " use a:text if the ftplugin didn't kick in
  if !exists("result")
    let result = a:text
  end

  " return an array, regardless
  if type(result) == type("")
    return [result]
  else
    return result
  end
endfunction

function! s:SlimyGetConfig()
  " b:slimy_config already configured...
  if exists("b:slimy_config")
    return
  end
  " assume defaults, if they exist
  if exists("g:slimy_default_config")
    let b:slimy_config = g:slimy_default_config
  end
  " skip confirmation, if configured
  if exists("g:slimy_dont_ask_default") && g:slimy_dont_ask_default
    return
  end
  " prompt user
  call s:SlimyDispatch('Config')
endfunction

function! slimy#send_op(type, ...) abort
  call s:SlimyGetConfig()

  let sel_save = &selection
  let &selection = "inclusive"
  let rv = getreg('"')
  let rt = getregtype('"')

  if a:0  " Invoked from Visual mode, use '< and '> marks.
    silent exe "normal! `<" . a:type . '`>y'
  elseif a:type == 'line'
    silent exe "normal! '[V']y"
  elseif a:type == 'block'
    silent exe "normal! `[\<C-V>`]\y"
  else
    silent exe "normal! `[v`]y"
  endif

  call setreg('"', @", 'V')
  call slimy#send(@")

  let &selection = sel_save
  call setreg('"', rv, rt)

  call s:SlimyRestoreCurPos()
endfunction

function! slimy#send_range(startline, endline) abort
  call s:SlimyGetConfig()

  let rv = getreg('"')
  let rt = getregtype('"')
  silent exe a:startline . ',' . a:endline . 'yank'
  call slimy#send(@")
  call setreg('"', rv, rt)
endfunction

function! slimy#send_lines(count) abort
  call s:SlimyGetConfig()

  let rv = getreg('"')
  let rt = getregtype('"')
  silent exe 'normal! ' . a:count . 'yy'
  call slimy#send(@")
  call setreg('"', rv, rt)
endfunction

function! slimy#store_curpos()
  if g:slimy_preserve_curpos == 1
    let has_getcurpos = exists("*getcurpos")
    if has_getcurpos
      " getcurpos() doesn't exist before 7.4.313.
      let s:cur = getcurpos()
    else
      let s:cur = getpos('.')
    endif
  endif
endfunction

function! s:SlimyRestoreCurPos()
  if g:slimy_preserve_curpos == 1 && exists("s:cur")
    call setpos('.', s:cur)
    unlet s:cur
  endif
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Public interface
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! slimy#send(text)
  call s:SlimyGetConfig()

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
      call s:SlimyDispatch('Send', b:slimy_config, piece)
    end
  endfor
endfunction

function! slimy#config() abort
  call inputsave()
  call s:SlimyDispatch('Config')
  call inputrestore()
endfunction

" delegation
function! s:SlimyDispatch(name, ...)
  let target = substitute(tolower(g:slimy_target), '\(.\)', '\u\1', '') " Capitalize
  return call("s:" . target . a:name, a:000)
endfunction

