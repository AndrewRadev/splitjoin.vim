function! sj#js#SplitObjectLiteral()
  let [from, to] = sj#LocateCurlyBracesOnLine()

  if from < 0 && to < 0
    return 0
  else
    let args = s:ParseHash(from, to)
    let body = "{\n".join(args, ",\n")."\n}"
    call sj#ReplaceMotion('Va{', body)

    return 1
  endif
endfunction

function! sj#js#JoinObjectLiteral()
  let line = getline('.')

  if line =~ '{\s*$'
    call search('{', 'c', line('.'))
    let body = sj#GetMotion('Vi{')
    let body = join(map(split(body, "\n"), 'sj#Trim(v:val)'), ' ')
    call sj#ReplaceMotion('Va{', '{ '.body.' }')

    return 1
  else
    return 0
  endif
endfunction

function! s:ParseHash(from, to)
  let body = sj#Trim(sj#GetCols(a:from, a:to))
  let body = substitute(body, '{\(.*\)}', '\1', '')
  return map(split(body, ','), 'sj#Trim(v:val)')
endfunction
