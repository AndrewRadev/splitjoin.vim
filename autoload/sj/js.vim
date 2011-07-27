function! sj#js#SplitObjectLiteral()
  return 0

  let [from, to] = [-1, -1]

  let [_line, to] = searchpairpos('{', '', '}', 'c', line('.'))
  if to > 0
    let [_line, from] = searchpos('{', 'cb', line('.'))
  endif

  Decho [from, to]

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
  let body = sj#GetCols(a:from, a:to)
  return map(split(body, ','), 'sj#Trim(v:val)')
endfunction
