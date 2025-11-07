" Only real syntax that's interesting is cParen and cConditional
let s:skip = sj#SkipSyntax(['cComment', 'cCommentL', 'cString', 'cCppString', 'cBlock'])

function! sj#c#SplitFuncall()
  let [from, to] = sj#LocateBracesAroundCursor('(', ')', s:skip)
  if from < 0 && to < 0
    return 0
  endif

  let items = sj#ParseJsonObjectBody(from + 1, to - 1)

  let body = "("
  if sj#settings#Read('c_argument_split_first_newline')
    let body = "(\n"
  endif

  let body .= join(items, ",\n")

  if sj#settings#Read('c_argument_split_last_newline')
    let body .= "\n)"
  else
    let body .= ")"
  endif

  call sj#ReplaceMotion('va(', body)
  return 1
endfunction

function! sj#c#SplitIfClause()
  if sj#SearchUnderCursor('if\s*(.\{-})', '', s:skip) <= 0
    return 0
  endif

  let items = sj#TrimList(split(getline('.'), '\ze\(&&\|||\)'))
  let body  = join(items, "\n")

  call sj#ReplaceMotion('V', body)
  return 1
endfunction

function! sj#c#JoinFuncall()
  if sj#SearchUnderCursor('([^)]*\s*$', '', s:skip) <= 0
    return 0
  endif

  normal! va(J
  return 1
endfunction

function! sj#c#JoinIfClause()
  if sj#SearchUnderCursor('if\s*([^)]*\s*$', '', s:skip) <=  0
    return 0
  endif

  call sj#PushCursor()
  normal! f(
  normal! va(J
  call sj#PopCursor()
  return 1
endfunction
