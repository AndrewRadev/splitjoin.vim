function! sj#lua#SplitFunction()
  let function_pattern = '\(\<function\>\s*(.\{-})\)\(.*\)\<end\>'
  let line             = getline('.')

  if line !~ function_pattern
    return 0
  else
    let head = sj#ExtractRx(line, function_pattern, '\1')
    let body = sj#Trim(sj#ExtractRx(line, function_pattern, '\2'))

    let replacement = head."\n".body."\nend"
    let new_line    = substitute(line, function_pattern, replacement, '')

    call sj#ReplaceMotion('V', new_line)

    return 1
  endif
endfunction

function! sj#lua#JoinFunction()
  return 0
endfunction
