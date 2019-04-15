function! slimy#stata_EscapeText(text)
	let remove_comments = substitute(a:text, '///\s*\n', " ", "g")
	return remove_comments
endfunction
