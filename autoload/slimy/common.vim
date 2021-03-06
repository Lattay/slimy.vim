" guess correct number of spaces to indent
" (tabs cause 'no completion found' messages)
function! slimy#common#get_indent_string() abort
    return repeat(' ', 4)
endfunction

" replace tabs by spaces
function! slimy#common#tab_to_spaces(text) abort
    return substitute(a:text, '	', slimy#common#get_indent_string(), 'g')
endfunction

" change string into array of lines
function! slimy#common#lines(text) abort
    return split(a:text, '\n')
endfunction

" change lines back into text
function! slimy#common#unlines(lines) abort
    return join(a:lines, '\n') . '\n'
endfunction
