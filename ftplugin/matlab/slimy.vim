" Check if line is commented out
function! s:Is_comment(line)
    return (match(a:line, "^[ \t]*%.*") >= 0)
endfunction

" Remove commented out lines
function! s:Remove_line_comments(lines)
    return filter(copy(a:lines), "!s:Is_comment(v:val)")
endfunction

" slimy handler
function! slimy#matlab_EscapeText(text)
    let l:lines = slimy#common#lines(slimy#common#tab_to_spaces(a:text))
    let l:lines = s:Remove_line_comments(l:lines)
    return slimy#common#unlines(l:lines)
endfunction
