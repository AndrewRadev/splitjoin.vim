function! sj#elm#SplitList()
  let [from, to] = sj#LocateBracesAroundCursor('[', ']')

  echomsg "from = " from
  echomsg "to = " to

  if from < 0
    return 0
  endif

  let [from, to, args] = sj#argparser#elm#ParseArguments(from + 1, to - 1, getline('.'))

  if from < 0
    return 0
  endif

  let replacement = join(args, "\n, ")

  let replacement = " ".replacement."\n"
  call sj#ReplaceCols(from, to, replacement)

  return 1
endfunction

