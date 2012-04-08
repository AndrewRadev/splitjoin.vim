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
    endif

    return 1
  endif
endfunction

function! sj#php#JoinArray()
  call sj#JoinHashWithRoundBraces()
endfunction
