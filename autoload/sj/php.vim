function! sj#php#SplitArray()
  let arraypattern = '\(array\)\s*(\(.*\))'
  let line         = getline('.')

  if line !~? arraypattern
    return 0
  else
    let [from, to] = sj#php#LocateParenOnLine()
    if from < 0 && to < 0
      return 0
    else
      let pairs = s:ParseHash(from + 1, to - 1)
      let body  = "(\n".join(pairs, ",\n")."\n)"
      call sj#ReplaceMotion('Va(', body)

      let body_start = line('.') + 1
      let body_end   = body_start + len(pairs)

      call sj#PushCursor()
      exe "normal! jV".(body_end - body_start)."j2="
      call sj#PopCursor()

    endif
    return 1
  endif
endfunction

function! sj#php#JoinArray()
  call sj#JoinHashWithRoundBraces()
endfunction

function! s:ParseHash(from, to)
  " Js object parser works just fine
  let parser = sj#argparser#js#Construct(a:from, a:to, getline('.'))
  call parser.Process()
  return parser.args
endfunction

function! sj#php#LocateParenOnLine()
  let [_bufnum, line, col, _off] = getpos('.')

  if getline('.') !~ '(.*)'
    return [-1, -1]
  endif

  let found = searchpair('(', '', ')', 'cb', '', line('.'))
  if found <= 0
    let found = search('(', '', '', line('.'))
  endif

  if found > 0
    let from = col('.') - 1
    normal! %
    let to = col('.')

    return [from, to]
  else
    return [-1, -1]
  endif
endfunction
