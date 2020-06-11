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

  let betterMatch = sj#elm#LocateOutermostBraces(currentMatch[0] - 1)

  if betterMatch[0] < 1
    return currentMatch
  endif

  return betterMatch
endfunction

function! sj#elm#SplitList()
  call sj#PushCursor()

  let [from, to] = sj#elm#LocateOutermostBraces(col('.'))

  if from < 0
    return 0
  endif

  let parts = sj#elm#SplitParts(from, to)

  if len(parts) <= 2
    return 0
  endif

  let replacement = join(parts, "\n")

  call cursor(line('.'), from)
  let [previousLine, previousCol] = searchpos('\S', 'bn')
  if previousLine == line('.') && previousCol > 0 && sj#elm#CharAt(previousCol) =~ '[=:]'
    let replacement = "\n".replacement
    let from = previousCol + 1
  end

  call sj#ReplaceCols(from, to, replacement)

  call sj#PopCursor()

  return 1
endfunction

function sj#elm#SplitParts(from, to)
  call sj#PushCursor()
  let skip = sj#SkipSyntax(['elmString', 'elmTripleString', 'elmComment'])
  let currentLine = line('.')

  call cursor(currentLine, a:from)

  let openingCol = a:from
  let openingChar = sj#elm#CurrentChar()
  let parts = []

  while col('.') < a:to
    call searchpair('[{(\[]', ',\|\(\(<\)\@<!|\(>\)\@!\)', '[})\]]', '', skip, currentLine)
    let closingCol = col('.')
    let closingChar = sj#elm#CurrentChar()
    let part = openingChar.' '.sj#Trim(sj#GetByPosition([0, currentLine, openingCol + 1, 0], [0, currentLine, closingCol - 1, 0]))
    call add(parts, part)
    let openingCol = closingCol
    let openingChar = closingChar
    call cursor(currentLine, openingCol)
  endwhile

  call add(parts, sj#elm#CharAt(a:to))

  call sj#PopCursor()

  return parts
endfunction


function sj#elm#CharAt(column)
  return getline('.')[a:column - 1]
endfunction

function sj#elm#CurrentChar()
  return sj#elm#CharAt(col('.'))
endfunction
