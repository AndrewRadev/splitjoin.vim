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
    call sj#ReplaceMotion('vi{', "\n".sj#Trim(body)."\n")
    return 1
  endif

  let start_col = col('.')
  let end_col = s:JumpBracketsTill('[\])};,]')

  let body = sj#GetCols(start_col, end_col)
  if getline('.') =~ ';\s*\%(//.*\)\=$'
    let replacement = "{\nreturn ".body.";\n}"
  else
    let replacement = "{\nreturn ".body."\n}"
  endif

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

" Note: copied from js.vim
"
function! s:JumpBracketsTill(end_pattern)
  try
    " ensure we can't go to the next line:
    let saved_whichwrap = &whichwrap
    set whichwrap-=l
    " ensure we can go to the very end of the line
    let saved_virtualedit = &virtualedit
    set virtualedit=onemore

    let opening_brackets = '([{"'''
    let closing_brackets = ')]}"'''

    let remainder_of_line = s:RemainderOfLine()
    while remainder_of_line !~ '^'.a:end_pattern
          \ && remainder_of_line !~ '^\s*$'
      let [opening_bracket_match, offset] = s:BracketMatch(remainder_of_line, opening_brackets)
      let [closing_bracket_match, _]      = s:BracketMatch(remainder_of_line, closing_brackets)

      if opening_bracket_match < 0 && closing_bracket_match >= 0
        let closing_bracket = closing_brackets[closing_bracket_match]
        " there's an extra closing bracket from outside the list, bail out
        break
      elseif opening_bracket_match >= 0
        " then try to jump to the closing bracket
        let opening_bracket = opening_brackets[opening_bracket_match]
        let closing_bracket = closing_brackets[opening_bracket_match]

        " first, go to the opening bracket
        if offset > 0
          exe "normal! ".offset."l"
        end

        if opening_bracket == closing_bracket
          " same bracket (quote), search for it, unless it's escaped
          call search('\\\@<!\V'.closing_bracket, 'W', line('.'))
        else
          " different closing, use searchpair
          call searchpair('\V'.opening_bracket, '', '\V'.closing_bracket, 'W', '', line('.'))
        endif
      endif

      normal! l
      let remainder_of_line = s:RemainderOfLine()
      if remainder_of_line =~ '^$'
        " we have no more content, the current column is the end of the expression
        return col('.')
      endif
    endwhile

    " we're past the final column of the expression, so return the previous
    " one:
    return col('.') - 1
  finally
    let &whichwrap = saved_whichwrap
    let &virtualedit = saved_virtualedit
  endtry
endfunction

function! s:RemainderOfLine()
  return strpart(getline('.'), col('.') - 1)
endfunction

function! s:BracketMatch(text, brackets)
  let index  = 0
  let offset = match(a:text, '^\s*\zs')
  let text   = strpart(a:text, offset)

  for char in split(a:brackets, '\zs')
    if text[0] ==# char
      return [index, offset]
    else
      let index += 1
    endif
  endfor

  return [-1, 0]
endfunction
