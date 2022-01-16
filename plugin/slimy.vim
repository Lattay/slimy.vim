if exists('g:loaded_slimy') || &compatible || v:version < 700
    finish
endif
let g:loaded_slimy = 1

call slimy#config#pre_config()

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Setup key bindings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

command -bar -nargs=0 SlimyConfig call slimy#config()
command -range=% -bar -nargs=0 SlimySend call slimy#send_range(<line1>, <line2>)

noremap <sid>Op <cmd>call slimy#store_curpos()<cr><cmd>set opfunc=slimy#send_op<cr>g@

noremap <unique> <script> <silent> <plug>(slimy_send_region) <cmd>call slimy#send_reg(visualmode() ==# 'V')<cr>
noremap <unique> <script> <silent> <plug>(slimy_send_motion) <sid>Op
noremap <unique> <script> <silent> <plug>(slimy_send_paragraph) <sid>Opip
noremap <unique> <script> <silent> <plug>(slimy_config) <cmd>SlimyConfig<cr>

if !exists('g:slimy_no_mappings') || !g:slimy_no_mappings
    if !hasmapto('<plug>(slimy_region_send)', 'x')
        xmap <c-c><c-c> <plug>(slimy_send_region)
    endif

    if !hasmapto('<plug>(slimy_paragraph_send)', 'n')
        nmap <c-c><c-c> <plug>(slimy_send_paragraph)
    endif

    if !hasmapto('<plug>(slimy_config)', 'n')
        nmap <c-c>v <plug>(slimy_config)
    endif
endif
