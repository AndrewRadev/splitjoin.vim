let s:skip = sj#SkipSyntax(['javaComment', 'javaString'])

function! sj#java#SplitIfClause()
  if sj#SearchUnderCursor('if\s*(.\{-})\s*{', 'e', s:skip) <= 0
    return 0
  endif

  let body = sj#GetMotion('vi{')
  if body =~ '\n'
    " it's more than one line, nevermind
    return 0
  endif

  call sj#ReplaceMotion('va{', "{\n".sj#Trim(body)."\n}")
  return 1
endfunction

function! sj#java#SplitFuncall()
  if sj#SearchUnderCursor('(.\{-})', '', s:skip) <= 0
    return 0
  endif

  call sj#PushCursor()

  normal! l
  let start = col('.')
  normal! h%h
  let end = col('.')

  let items = sj#ParseJsonObjectBody(start, end)
  let body = '('.join(items, ",\n").')'

  call sj#PopCursor()

  call sj#ReplaceMotion('va(', body)
  return 1
endfunction

function! sj#java#JoinIfClause()
  if sj#SearchUnderCursor('if\s*(.\{-})\s*{$', '', s:skip) <=  0
    return 0
  endif

  call sj#PushCursor()
  normal! f{
  normal! va{J
  call sj#PopCursor()
  return 1
endfunction

function! sj#java#JoinFuncall()
  if sj#SearchUnderCursor('([^)]*\s*$', '', s:skip) <= 0
    return 0
  endif

  normal! va(J
  return 1
endfunction
