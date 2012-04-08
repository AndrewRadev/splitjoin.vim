function! sj#python#SplitStatement()
  let line = getline('.')

  if line =~ '^[^:]*:\s*\S'
    let replacement = substitute(line, ':\s*', ":\n", '')
    call sj#ReplaceMotion('V', replacement)

    return 1
  else
    return 0
  endif
endfunction

function! sj#python#JoinStatement()
  let line = getline('.')

  if line =~ '^[^:]*:\s*$'
    join

    return 1
  else
    return 0
  endif
endfunction

function! sj#python#SplitDict()
  let [from, to] = sj#LocateBracesOnLine('{', '}')

  if from < 0 && to < 0
    return 0
  else
    let pairs = sj#ParseJsonObjectBody(from + 1, to - 1)
    let body  = "{\n".join(pairs, ",\n")."\n}"
    call sj#ReplaceMotion('Va{', body)

    let body_start = line('.') + 1
    let body_end   = body_start + len(pairs)

    call sj#PushCursor()
    exe "normal! jV".(body_end - body_start)."j2>"
    call sj#PopCursor()

    if g:splitjoin_align
      call sj#Align(body_start, body_end - 1, 'json_object')
    endif

    return 1
  endif
endfunction

function! sj#python#JoinDict()
  let line = getline('.')

  if line =~ '{\s*$'
    call search('{', 'c', line('.'))
    let body = sj#GetMotion('Vi{')

    let lines = sj#TrimList(split(body, "\n"))
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
