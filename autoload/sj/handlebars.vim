function! sj#handlebars#SplitComponent()
  if !sj#SearchUnderCursor('{{\%(\k\|-\|\/\)\+ .\{-}}}')
    return 0
  endif

  let body = sj#GetMotion('vi{')
  let body = substitute(body, '\s\+\(\k\+=\)', '\n\1', 'g')
  call sj#ReplaceMotion('vi{', body)
  return 1
endfunction

function! sj#handlebars#JoinComponent()
  if !(sj#SearchUnderCursor('{{\%(\k\|-\|\/\)\+') && getline('.') !~ '}}')
    return 0
  endif

  normal! vi{J
  return 1
endfunction
