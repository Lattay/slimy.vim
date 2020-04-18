if exists('g:loaded_slimy') || &compatible || v:version < 700
    finish
endif
let g:loaded_slimy = 1

call slimy#config#pre_config()

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Setup key bindings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

command -bar -nargs=0 SlimyConfig call slimy#config()
command -range -bar -nargs=0 SlimySend call slimy#send_range(<line1>, <line2>)
command -nargs=+ SlimySend1 call slimy#send(<q-args> . '\r')
command -nargs=+ SlimySend0 call slimy#send(<args>)
command! SlimySendCurrentLine call slimy#send(getline('.') . '\r')

noremap <SID>Operator <cmd>call slimy#store_curpos()<cr><cmd>set opfunc=slimy#send_op<cr>g@

noremap <unique> <script> <silent> <Plug>(slimy_send_region) <cmd>call slimy#send_op(visualmode(), 1)<cr>
noremap <unique> <script> <silent> <Plug>(slimy_send_line) <cmd>call slimy#send_lines(v:count1)<cr>
noremap <unique> <script> <silent> <Plug>(slimy_send_motion) <SID>Operator
noremap <unique> <script> <silent> <Plug>(slimy_send_paragraph) <SID>Operatorip
noremap <unique> <script> <silent> <Plug>(slimy_config) <cmd>SlimyConfig<cr>

if !exists('g:slimy_no_mappings') || !g:slimy_no_mappings
    if !hasmapto('<Plug>(slimy_region_send)', 'x')
        xmap <c-c><c-c> <Plug>(slimy_send_region)
    endif

    if !hasmapto('<Plug>(slimy_paragraph_send)', 'n')
        nmap <c-c><c-c> <Plug>(slimy_send_paragraph)
    endif

    if !hasmapto('<Plug>(slimy_config)', 'n')
        nmap <c-c>v <Plug>(slimy_config)
    endif
endif

