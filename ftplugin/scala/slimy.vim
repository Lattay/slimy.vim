function! slimy#scala_EscapeText(text)
  return [":paste\n", a:text, ""]
endfunction
