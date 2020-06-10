function! sj#elm#LocateClosestBraces(column)
  call sj#PushCursor()

  let skip = sj#SkipSyntax(['elmString', 'elmTripleString', 'elmComment'])
  let currentLine = line('.')

  call cursor(currentLine, a:column)
  let from = searchpairpos('[{([]', '', '[})]]', 'bcn', skip, currentLine)

  if from[0] == 0
    call sj#PopCursor()

    return [-1, -1]
  end

  call cursor(from[0], from[1])
  normal! %

  if line('.') != currentLine
    call sj#PopCursor()

    return [-1, -1]
  endif 

  let to = col('.')

  call sj#PopCursor()

  return [from[1], to]
endfunction

function! sj#elm#LocateOutermostBraces(column)
  if a:column < 1
    return [-1, -1]
  endif

  let currentMatch = sj#elm#LocateClosestBraces(a:column)

  if currentMatch[0] < 1
    return [-1, -1]
  endif

  echomsg currentMatch

  let betterMatch = sj#elm#LocateOutermostBraces(currentMatch[0] - 1)

  echomsg betterMatch

  if betterMatch[0] < 1
    return currentMatch
  endif

  return betterMatch
endfunction

function! sj#elm#SplitList()
  let [from, to] = sj#elm#LocateOutermostBraces(col('.'))

  if from < 0
    return 0
  endif

  let args = sj#elm#ListArgs(from, to)

  if len(args) < 2
    return 0
  endif

  let replacement = join(args, "\n, ")

  let replacement = sj#elm#CharAt(from)." ".replacement."\n".sj#elm#CharAt(to)
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

function sj#elm#CharAt(column)
  return getline('.')[a:column - 1]
endfunction

function sj#elm#CurrentChar()
  return sj#elm#CharAt(col('.'))
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
