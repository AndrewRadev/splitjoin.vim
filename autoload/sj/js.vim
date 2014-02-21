function! sj#js#SplitObjectLiteral()
  let [from, to] = sj#LocateBracesOnLine('{', '}')

  if from < 0 && to < 0
    return 0
  else
    let pairs = sj#ParseJsonObjectBody(from + 1, to - 1)
    let body  = "{\n".join(pairs, ",\n")."\n}"
    call sj#ReplaceMotion('Va{', body)

    if g:splitjoin_align
      let body_start = line('.') + 1
      let body_end   = body_start + len(pairs) - 1
      call sj#Align(body_start, body_end, 'json_object')
    endif

    return 1
  endif
endfunction

function! sj#js#SplitFunction()
  if expand('<cword>') == 'function' && getline('.') =~ '\<function\>.*(.*)\s*{.*}'
    normal! f{
    return sj#js#SplitObjectLiteral()
  else
    return 0
  endif
endfunction

function! sj#js#JoinObjectLiteral()
  let line = getline('.')

  if line =~ '{\s*$'
    call search('{', 'c', line('.'))
    let body = sj#GetMotion('Vi{')

    let lines = split(body, "\n")
    let lines = sj#TrimList(lines)
    if g:splitjoin_normalize_whitespace
      let lines = map(lines, 'substitute(v:val, ":\\s\\+", ": ", "")')
    endif

    let body = join(lines, ' ')

    call sj#ReplaceMotion('Va{', '{ '.body.' }')

    return 1
  else
    return 0
  endif
endfunction

function! sj#js#SplitArray()
  let lineno = line('.')
  let indent = indent('.')

  let [from, to] = sj#LocateBracesOnLine('[', ']')

  if from < 0 && to < 0
    return 0
  endif

  let items = sj#ParseJsonObjectBody(from + 1, to - 1)
  let body  = "[\n".join(items, ",\n")."\n]"
  call sj#ReplaceMotion('Va[', body)

  " built-in js indenting doesn't indent this properly
  for l in range(lineno + 1, lineno + len(items))
    call sj#SetIndent(l, indent + &sw)
  endfor
  " closing bracket
  let end_line = lineno + len(items) + 1
  call sj#SetIndent(end_line, indent)

  return 1
endfunction

function! sj#js#JoinArray()
  let line = getline('.')

  if line !~ '[\s*$'
    return 0
  endif

  call search('[', 'c', line('.'))
  let body = sj#GetMotion('Vi[')

  let lines = split(body, "\n")
  let lines = sj#TrimList(lines)
  let body  = sj#Trim(join(lines, ' '))

  call sj#ReplaceMotion('Va[', '['.body.']')

  return 1
endfunction
