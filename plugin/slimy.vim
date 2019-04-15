if existsy'g:loaded_slimy') || &cp || v:version < 700
  finish
endif
let g:loaded_slimy = 1

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Setup key bindings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

command -bar -nargs=0 SlimyConfig call slimy#config()
command -range -bar -nargs=0 SlimySend call slimy#send_range(<line1>, <line2>)
command -nargs=+ SlimySend1 call slimy#send(<q-args> . "\r")
command -nargs=+ SlimySend0 call slimy#send(<args>)
command! SlimySendCurrentLine call slimy#send(getline(".") . "\r")

noremap <SID>Operator :<c-u>call slimy#store_curpos()<cr>:set opfunc=slimy#send_op<cr>g@

noremap <unique> <script> <silent> <Plug>SlimyRegionSend :<c-u>call slimy#send_op(visualmode(), 1)<cr>
noremap <unique> <script> <silent> <Plug>SlimyLineSend :<c-u>call slimy#send_lines(v:count1)<cr>
noremap <unique> <script> <silent> <Plug>SlimyMotionSend <SID>Operator
noremap <unique> <script> <silent> <Plug>SlimyParagraphSend <SID>Operatorip
noremap <unique> <script> <silent> <Plug>SlimyConfig :<c-u>SlimyConfig<cr>

if !exists("g:slimy_no_mappings") || !g:slimy_no_mappings
  if !hasmapto('<Plug>SlimyRegionSend', 'x')
    xmap <c-c><c-c> <Plug>SlimyRegionSend
  endif

  if !hasmapto('<Plug>SlimyParagraphSend', 'n')
    nmap <c-c><c-c> <Plug>SlimyParagraphSend
  endif

  if !hasmapto('<Plug>SlimyConfig', 'n')
    nmap <c-c>v <Plug>SlimyConfig
  endif
endif

