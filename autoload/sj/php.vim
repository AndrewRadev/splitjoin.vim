function! sj#php#SplitArray()
  let arraypattern = '\(array\)\s*(\(.*\))'
  let line         = getline('.')

  if line !~? arraypattern
    return 0
  else
    let [from, to] = sj#LocateBracesOnLine('(', ')')

    if from < 0 && to < 0
      return 0
    else
      let pairs = sj#ParseJsonObjectBody(from + 1, to - 1)
      let body  = "(\n".join(pairs, ",\n")."\n)"
      call sj#ReplaceMotion('Va(', body)

      let body_start = line('.') + 1
      let body_end   = body_start + len(pairs)

      call sj#PushCursor()
      exe "normal! jV".(body_end - body_start)."j2="
      call sj#PopCursor()

      if g:splitjoin_align
        call sj#Align(body_start, body_end, 'hashrocket')
      endif
    endif

    return 1
  endif
endfunction

function! sj#php#JoinArray()
  normal! $

  let body = sj#GetMotion('Vi(',)
  if g:splitjoin_normalize_whitespace
    let body = substitute(body, '\s*=>\s*', ' => ', 'g')
  endif
  let body = join(sj#TrimList(split(body, "\n")), ' ')
  call sj#ReplaceMotion('Va(', '('.body.')')

  return 1
endfunction
