" Only real syntax that's interesting is cParen and cConditional
let s:skip = sj#SkipSyntax('cComment', 'cCommentL', 'cString', 'cBlock')

function! sj#c#SplitFuncall()
  if sj#SearchUnderCursor('(.\{-})') <= 0
    return 0
  endif
  echom "Looking for function call"

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


function! sj#c#SplitIfClause()
    if sj#SearchUnderCursor('if\s*(.\{-})') <= 0
        return 0
    endif

    let items = sj#TrimList(split(getline('.'), '\ze\(&&\|||\)'))
    let body  = join(items, "\n")

    call sj#ReplaceMotion('V', body)
    return 1
endfunction


function! sj#c#JoinFuncall()
  if sj#SearchUnderCursor('([^)]*\s*$') <= 0
    return 0
  endif

  exe 'normal! va(J'
  return 1
endfunction


function! sj#c#JoinIfClause()
    if sj#SearchUnderCursor('if\s*([^)]*\s*$') <=  0
        return 0
    endif

    call sj#PushCursor()
    normal! f(
    normal! va(J
    call sj#PopCursor()
    return 1
endfunction
" Need to add something for splitting the if statement on || and &&
