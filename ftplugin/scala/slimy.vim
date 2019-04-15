function! slimy#scala#EscapeText(text)
  return [":paste\n", a:text, ""]
endfunction
