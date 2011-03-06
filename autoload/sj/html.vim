function! sj#html#Split()
  let line = getline('.')
  let tag_regex = '\(<.\{-}>\)\(.*\)\(<\/.\{-}>\)'

  if line =~ tag_regex
    call sj#ReplaceMotion('V', substitute(line, tag_regex, '\1\n\2\n\3', ''))
    return 1
  else
    return 0
  endif
endfunction

" TODO check if we're really on a tag
function! sj#html#Join()
  let body = sj#GetMotion('vit')

  if line("'<") == line("'>")
    " then it's just one line, ignore
    return 0
  endif

  let body = sj#Trim(body)
  let body = join(map(split(body, "\n"), 'sj#Trim(v:val)'), ' ')

  call sj#ReplaceMotion('vit', body)

  return 1
endfunction
