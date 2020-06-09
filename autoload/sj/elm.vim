function! sj#elm#LocateOutermostBracesAroundCursor()
  call sj#PushCursor()

  let [from, to] = sj#LocateBracesAroundCursor('[', ']')

  while from > 0
    call cursor(line('.'), from - 1)

    let [newFrom, newTo] = sj#LocateBracesAroundCursor('[', ']')

    if newFrom < 0
      break
    endif

    let [from, to] = [newFrom, newTo]
  endwhile

  call sj#PopCursor()

  return [from, to]
endfunction

function! sj#elm#SplitList()
  let [from, to] = sj#elm#LocateOutermostBracesAroundCursor()

  if from < 0
    return 0
  endif

  let args = sj#elm#ListArgs(from, to)

  if len(args) < 2
    return 0
  endif

  let replacement = join(args, "\n, ")

  let replacement = "[ ".replacement."\n]"
  call sj#ReplaceCols(from, to, replacement)

  return 1
endfunction

function! sj#elm#SplitTuple()
  let [from, to] = sj#LocateBracesAroundCursor('(', ')')

  if from < 0
    return 0
  endif

  let args = sj#elm#ListArgs(from, to)

  if len(args) < 2
    return 0
  endif

  let replacement = join(args, "\n, ")

  let replacement = "( ".replacement."\n)"
  call sj#ReplaceCols(from, to, replacement)

  return 1
endfunction

function sj#elm#ListArgs(from, to)
  call sj#PushCursor()
  let bufferBefore = @@

  call cursor(line('.'), a:from + 1)

  let args = []
  let arg = ""

  while col('.') < a:to
    let character = sj#elm#CurrentChar()
    if character == ","
      if len(arg) > 0
        call add(args, arg)
        let arg = ""
      endif
      call cursor(line('.'), col('.') + 1)
    elseif character =~ "[\"'{\[(]"
      let arg = sj#elm#AddToArgAndGetToNextWord(arg, sj#elm#CaptureMatching(character))
    else
      let arg = sj#elm#AddToArgAndGetToNextWord(arg, sj#elm#CaptureWord())
    endif
  endwhile

  if len(arg) > 0
    call add(args, arg)
  endif

  let @@ = bufferBefore
  call sj#PopCursor()

  return args
endfunction

function sj#elm#CaptureMatching(character)
  execute "normal! ya" . a:character
  return @@
endfunction

function sj#elm#CaptureWord()
  normal! yiw
  return @@
endfunction

function sj#elm#CurrentChar()
  return getline('.')[col('.') - 1]
endfunction

function sj#elm#AddToArgAndGetToNextWord(arg, newPart)
  let newArg = sj#Trim(sj#elm#AddToArg(a:arg, a:newPart))
  call cursor(line('.'), col('.') + len(a:newPart))
  return newArg
endfunction

function sj#elm#AddToArg(arg, newPart)
  if a:arg == ""
    return a:newPart
  endif

  if a:newPart == "." || a:arg =~ "\\.$"
    return join([a:arg, a:newPart], "")
  else

  return join([a:arg, a:newPart], " ")
endfunction
