function! sj#lua#SplitFunction()
  let function_pattern = '\(\<function\>.\{-}(.\{-})\)\(.*\)\<end\>'
  let line             = getline('.')

  if line !~ function_pattern
    return 0
  else
    let head = sj#ExtractRx(line, function_pattern, '\1')
    let body = sj#Trim(sj#ExtractRx(line, function_pattern, '\2'))

    if sj#BlankString(body)
      let body = ''
    else
      let body = body."\n"
    endif

    let replacement = head."\n".body."end"
    let new_line    = substitute(line, function_pattern, replacement, '')

    call sj#ReplaceMotion('V', new_line)

    return 1
  endif
endfunction

function! sj#lua#JoinFunction()
  normal! 0
  if search('\<function\>', 'W', line('.')) < 0
    return 0
  endif

  let function_lineno = line('.')
  if searchpair('\<function\>', '', '\<end\>', 'W') <= 0
    return 0
  endif
  let end_lineno = line('.')

  let function_line = getline(function_lineno)
  let end_line      = getline(end_lineno)

  if end_lineno - function_lineno > 1
    let body_lines = sj#GetLines(function_lineno + 1, end_lineno - 1)
    let body_lines = sj#TrimList(body_lines)
    let body       = join(body_lines, '; ')
    let body       = ' '.body.' '
  else
    let body = ' '
  endif

  let replacement = function_line.body.end_line
  call sj#ReplaceLines(function_lineno, end_lineno, replacement)

  return 1
endfunction
