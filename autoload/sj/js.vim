function! sj#js#SplitObjectLiteral()
  let [from, to] = sj#LocateCurlyBracesOnLine()

  if from < 0 && to < 0
    return 0
  else
    let pairs = s:ParseHash(from + 1, to - 1)
    let body  = "{\n".join(pairs, ",\n")."\n}"
    call sj#ReplaceMotion('Va{', body)

    if g:splitjoin_align
      let body_start = line('.') + 1
      let body_end   = body_start + len(pairs) - 1
      call sj#Align(body_start, body_end, 'js_hash')
    endif

    return 1
  endif
endfunction

function! sj#js#JoinObjectLiteral()
  let line = getline('.')

  if line =~ '{\s*$'
    call search('{', 'c', line('.'))
    let body = sj#GetMotion('Vi{')

    let lines = split(body, "\n")
    let lines = map(lines, 'sj#Trim(v:val)')
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

function! s:ParseHash(from, to)
  let parser = sj#argparser#js#Construct(a:from, a:to, getline('.'))
  call parser.Process()
  return parser.args
endfunction
