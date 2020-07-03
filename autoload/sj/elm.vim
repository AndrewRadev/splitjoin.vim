" vim: foldmethod=marker

" Split / Join {{{1
"
" function! sj#elm#Join() {{{2
"
" Attempts to join the multiline tuple, record or list closest
" to current curspor position.
function! sj#elm#Join()
  let [from, to] = sj#elm#ClosestMultilineBraces()

  if from[0] < 0
    return 0
  endif

  let original = sj#GetByPosition([0, from[0], from[1]], [0, to[0], to[1]])
  let joined = sj#elm#JoinOuterBraces(sj#elm#JoinLines(original))
  call sj#ReplaceByPosition([0, from[0], from[1]], [0, to[0], to[1]], joined)

  return 1
endfunction

" function! sj#elm#Split() {{{2
"
" Attempts to split the tuple, record or list fursest to current
" curspor position on the same line.
function! sj#elm#Split()
  call sj#PushCursor()

  let [from, to] = sj#elm#CurrentLineOutermostBraces(col('.'))

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


" Helper functions {{{1

" function! sj#elm#SkipSyntax() {{{2
"
" Returns Elm's typical skippable syntax (strings and comments)
function! sj#elm#SkipSyntax()
  return sj#SkipSyntax(['elmString', 'elmTripleString', 'elmComment'])
endfunction

" function! sj#elm#CurrentLineClosestBraces(column) {{{2
"
" Returns the columns corresponding to the bracing pair closest
" to and surrounding given column as a list ([opening, closing]).
" Returns [-1, -1] when there is none on the same line.
function! sj#elm#CurrentLineClosestBraces(column)
  call sj#PushCursor()

  let skip = sj#elm#SkipSyntax()
  let currentLine = line('.')

  call cursor(currentLine, a:column)
  let from = searchpairpos('[{(\[]', '', '[})\]]', 'bcn', skip, currentLine)

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

" function! sj#elm#CurrentLineOutermostBraces(column) {{{2
"
" Returns the colums corresponding to the bracing pair furthest
" to and surrounding given column as a list ([opening, closing]).
" Returns [-1, -1] when there is none on the same line.
function! sj#elm#CurrentLineOutermostBraces(column)
  if a:column < 1
    return [-1, -1]
  endif

  let currentMatch = sj#elm#CurrentLineClosestBraces(a:column)

  if currentMatch[0] < 1
    return [-1, -1]
  endif

  let betterMatch = sj#elm#CurrentLineOutermostBraces(currentMatch[0] - 1)

  if betterMatch[0] < 1
    return currentMatch
  endif

  return betterMatch
endfunction

" function! sj#elm#ClosestMultilineBraces() {{{2
"
" Returns the position of the closest pair of multiline braces
" around the cursor.
"
" The positions are given as a couple of arrays:
"
"   [[startLine, startCol], [endLine, endCol]]
"
" When no position is found, returns:
"
"   [[-1, -1], [-1, -1]]
function! sj#elm#ClosestMultilineBraces()
  call sj#PushCursor()

  let skip = sj#elm#SkipSyntax()

  let currentLine = line('.')

  normal! $

  let [toLine, toCol] = searchpairpos('[{(\[]', '', '[})\]]', '', skip, line('$'))

  if toLine < currentLine
    call sj#PopCursor()
    return [[-1, -1], [-1, -1]]
  endif

  normal! %

  let fromLine = line('.')
  let fromCol = col('.')

  if fromLine >= toLine
    call sj#PopCursor()
    return [[-1, -1], [-1, -1]]
  endif

  call sj#PopCursor()

  return [[fromLine, fromCol], [toLine, toCol]]
endfunction

" function! sj#elm#JoinOuterBraces(text)
"
" Removes spaces separating the first and last char of a string
" with the closest non-space char found.
"
" ex:
"
"   [ 1, 2, 3 ] => [1, 2, 3]
function! sj#elm#JoinOuterBraces(text)
  return substitute(substitute(a:text, '\s*\(.\)$', '\1', ''), '^\(.\)\s*', '\1', '')
endfunction

" function! sj#elm#JoinLines(text)
"
" Joins lines in text, removing complementary spaces around
" newline chars when the last line starts with a ',' and keeping
" one whitespace for other cases.
function! sj#elm#JoinLines(text)
  return substitute(substitute(a:text, '\s*\n\s*,', ',', 'g'), '\s*\n\s*', ' ', 'g')
endfunction

" function! sj#elm#SplitParts(from, to)
"
" Splits a section of a line according to bracing characters
" rules.
"
" ex:
"   "[1,2,3]"
"   v
"   [ "[ 1", ", 2", ", 3", "]" ]
"
"   "{a | foo = bar, baz = buzz}"
"   v
"   [ "{ a", "| foo = bar", ", baz = buzz", "}" ]
function! sj#elm#SplitParts(from, to)
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

" function! sj#elm#CharAt(column)
"
" Returns the char sitting at given column of current line.
function! sj#elm#CharAt(column)
  return getline('.')[a:column - 1]
endfunction

" function! sj#elm#CurrentChar()
"
" Returns the character at current cursor's position
function! sj#elm#CurrentChar()
  return sj#elm#CharAt(col('.'))
endfunction
