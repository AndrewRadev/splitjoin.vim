let s:skip = sj#SkipSyntax(['javaComment', 'javaString'])

function! sj#java#SplitIfClause()
  if sj#SearchSkip('^\s*if (.\+) .\+;\?', s:skip, 'bc', line('.')) <= 0
    return 0
  endif

  " skip nested () brackets
  normal! ^w%l
  let body = sj#Trim(sj#GetMotion('vg_'))

  if body[0] == '{'
    let with_curly_brackets = 1
    normal! f{
    let body = sj#Trim(sj#GetMotion('vi{'))
  else
    let with_curly_brackets = 0
  endif

  if body =~ '\n'
    " it's more than one line, nevermind
    return 0
  endif

  if with_curly_brackets
    call sj#ReplaceMotion('va{', "{\n".body."\n}")
  else
    call sj#ReplaceMotion('vg_', "\n".body)
  endif

  return 1
endfunction

function! sj#java#JoinIfClause()
  if sj#SearchSkip('^\s*if\s*(.\+)\s*{$', s:skip, 'e', line('.')) > 0
    normal! va{J
    return 1
  elseif sj#SearchSkip('^\s*if\s*(.\+)\s*$', s:skip, 'bc', line('.')) > 0 &&
        \ indent(nextnonblank(line('.') + 1)) > indent(line('.'))
    normal! J
    return 1
  else
    return 0
  endif
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

function! sj#java#JoinFuncall()
  if sj#SearchUnderCursor('([^)]*\s*$', '', s:skip) <= 0
    return 0
  endif

  normal! va(J
  return 1
endfunction

function! sj#java#SplitLambda()
  if !sj#SearchUnderCursor('\%((.\{})\|\k\+\)\s*->\s*.*$')
    return 0
  endif

  call search('\%((.\{})\|\k\+\)\s*->\s*\zs.*$', 'W', line('.'))

  if strpart(getline('.'), col('.') - 1) =~ '^\s*{'
    " then we have a curly bracket group, easy split:
    let body = sj#GetMotion('vi{')
    call sj#ReplaceMotion('vi{', "\nreturn ".sj#Trim(body).";\n")
    return 1
  endif

  let start_col = col('.')
  let end_col = sj#JumpBracketsTill('[\])};,]', {'opening': '([{"''', 'closing': ')]}"'''})

  let body = sj#GetCols(start_col, end_col)
  let replacement = "{\nreturn ".body.";\n}"

  call sj#ReplaceCols(start_col, end_col, replacement)
  return 1
endfunction

function! sj#java#JoinLambda()
  if !sj#SearchUnderCursor('\%((.\{})\|\k\+\)\s*->\s*{\s*$')
    return 0
  endif

  normal! $

  let body = sj#Trim(sj#GetMotion('vi{'))
  let body = substitute(body, '^return\s*', '', '')
  let body = substitute(body, ';$', '', '')
  call sj#ReplaceMotion('va{', body)
  return 1
endfunction
