let s:skip_syntax = sj#SkipSyntax(['rustString', 'rustCommentLine', 'rustCommentBlock'])

function! sj#rust#SplitMatchClause()
  if !sj#SearchUnderCursor('^.*\s*=>\s*.*$')
    return 0
  endif

  call search('=>\s*\zs.', 'W', line('.'))

  let start_col = col('.')
  if !search(',\s*\%(//.*\)\=$', 'W', line('.'))
    return 0
  endif
  let comma_col = col('.')
  let end_col = comma_col - 1

  let body = sj#GetCols(start_col, end_col)
  call sj#ReplaceCols(start_col, comma_col, "{\n".body."\n},")
  return 1
endfunction

function! sj#rust#JoinMatchClause()
  if !sj#SearchUnderCursor('^.*\s*=>\s*{\s*$')
    return 0
  endif

  call search('=>\s*\zs{', 'W', line('.'))

  let body = sj#Trim(sj#GetMotion('Vi{'))
  if stridx(body, "\n") >= 0
    return 0
  endif

  call sj#ReplaceMotion('Va{', body)
  return 1
endfunction

function! sj#rust#SplitQuestionMark()
  if sj#SearchSkip('.?', s:skip_syntax, 'Wc', line('.')) <= 0
    return 0
  endif

  let current_line = line('.')
  let end_col = col('.')
  let question_mark_col = col('.') + 1
  let char = getline('.')[end_col - 1]

  if char =~ '\k'
    call search('\k\+?;', 'bWc', line('.'))
    let start_col = col('.')
  elseif char == '}'
    " go to opening bracket
    normal! %
    let start_col = col('.')
  elseif char == ')'
    " go to opening bracket
    normal! %
    " find first method-call char
    call search('\%(\k\|\.\|::\)\+!\?(', 'bWc')

    if line('.') != current_line
      " multiline expression, let's just ignore it
      return 0
    endif

    let start_col = col('.')
  endif

  " is it a Result, or an Option?
  let expr_type = s:FunctionReturnType()
  " default to a Result, if we can't find anything
  if expr_type == ''
    let expr_type = 'Result'
  endif
  let expr = sj#GetCols(start_col, end_col)

  if expr_type == 'Result'
    let replacement = join([
          \   "match ".expr." {",
          \   "  Ok(value) => value,",
          \   "  Err(e) => return Err(e.into()),",
          \   "}"
          \ ], "\n")
  elseif expr_type == 'Option'
    let replacement = join([
          \   "match ".expr." {",
          \   "  None => return None,",
          \   "  Some(value) => value,",
          \   "}"
          \ ], "\n")
  else
    echoerr "Unknown expr_type: ".expr_type
    return 0
  endif

  call sj#ReplaceCols(start_col, question_mark_col, replacement)
  return 1
endfunction

function! sj#rust#JoinMatchStatement()
  let match_pattern = '\<match .* {$'

  if sj#SearchSkip(match_pattern, s:skip_syntax, 'Wc', line('.')) <= 0
        \ && sj#SearchSkip(match_pattern, s:skip_syntax, 'Wbc', line('.')) <= 0
    return 0
  endif

  " is it a Result, or an Option?
  let return_type = s:FunctionReturnType()

  let match_position = getpos('.')
  let match_line = match_position[1]
  let match_col = match_position[2]

  let remainder_of_line = strpart(getline('.'), match_col - 1)
  let expr = substitute(remainder_of_line, '^match \(.*\) {$', '\1', '')

  let first_line   = match_line + 1
  let second_line  = match_line + 2
  let closing_line = match_line + 3

  if getline(first_line) =~ '^\s*Ok(\(\k\+\)) => \1' ||
        \ getline(second_line) =~ '^\s*Ok(\(\k\+\)) => \1'
    let expr_type = 'Result'
  elseif getline(first_line) =~ '^\s*None => return None,' ||
        \ getline(second_line) =~ '^\s*None => return None,'
    let expr_type = 'Option'
  else
    return 0
  endif

  if getline(second_line) =~ '^\s*Err(\k\+) => return Err(' ||
        \ getline(first_line) =~ '^\s*Err(\k\+) => return Err('
    let expr_type = 'Result'
  elseif getline(second_line) =~ '^\s*Some(\(\k\+\)) => \1' ||
        \ getline(first_line) =~ '^\s*Some(\(\k\+\)) => \1'
    let expr_type = 'Option'
  else
    return 0
  endif

  if search('^\s*}\ze', 'We', closing_line) <= 0
    return 0
  endif

  let end_position = getpos('.')

  if expr_type == return_type
    call sj#ReplaceByPosition(match_position, end_position, expr.'?')
  else
    call sj#ReplaceByPosition(match_position, end_position, expr.'.unwrap()')
  endif
endfunction

function! sj#rust#SplitBlockClosure()
  if search('|.\{-}|\s*\zs{', 'W', line('.')) <= 0
    return 0
  endif

  let closure_contents = sj#GetMotion('vi{')
  call sj#ReplaceMotion('va{', "{\n".sj#Trim(closure_contents)."\n}")
  return 1
endfunction

function! sj#rust#SplitExprClosure()
  if !sj#SearchUnderCursor('|.\{-}| .\{-})')
    return 0
  endif
  if search('|.\{-}| \zs.', 'W', line('.')) <= 0
    return 0
  endif

  let start_col = col('.')
  call s:JumpBracketsTill('\%([,;]\|$\)')
  let end_col = col('.') - 1

  let closure_contents = sj#GetCols(start_col, end_col)
  call sj#ReplaceCols(start_col, end_col, "{\n".closure_contents."\n}")
  return 1
endfunction

function! sj#rust#JoinClosure()
  if !sj#SearchUnderCursor('(|.\{-}| {\s*$')
    return 0
  endif
  if search('(|.\{-}| \zs{\s*$', 'W', line('.')) <= 0
    return 0
  endif

  let closure_contents = sj#Trim(sj#GetMotion('vi{'))
  call sj#ReplaceMotion('va{', closure_contents)
  return 1
endfunction

function! sj#rust#SplitUnwrapIntoEmptyMatch()
  let unwrap_pattern = '\S\.\%(unwrap\|expect\)('
  if sj#SearchUnderCursor(unwrap_pattern, 'e', s:skip_syntax) <= 0
    return 0
  endif

  normal! %
  let unwrap_end_col = col('.')
  normal! %
  call search(unwrap_pattern, 'Wb', line('.'))
  let end_col = col('.')

  let start_col = col('.')
  while start_col > 0
    let current_expr = strpart(getline('.'), start_col - 1, end_col)
    if current_expr =~ '^)'
      normal! %
    elseif current_expr =~ '^\%(::\|\.\)'
      normal! h
    else
      if sj#SearchSkip('\%(::\|\.\)\=\k\+\%#', s:skip_syntax, 'Wb', line('.')) <= 0
        break
      endif
    endif

    if start_col == col('.')
      " then nothing has changed this loop, break out
      break
    else
      let start_col = col('.')
    endif
  endwhile

  let expr = sj#GetCols(start_col, end_col)
  if expr == ''
    return 0
  endif

  if start_col >= end_col
    " the expression is probably split into several lines, let's ignore it
    return 0
  endif

  call sj#ReplaceCols(start_col, unwrap_end_col, join([
        \ "match ".expr." {",
        \ "",
        \ "}",
        \ ], "\n"))
  return 1
endfunction

" Note: special handling for < and >
"
function! s:JumpBracketsTill(end_pattern)
  let opening_brackets = '([<{"'''
  let closing_brackets = ')]>}"'''

  let original_whichwrap = &whichwrap
  set whichwrap+=l

  let remainder_of_line = s:RemainderOfLine()
  while remainder_of_line !~ '^'.a:end_pattern
    let [opening_bracket_match, offset] = s:BracketMatch(remainder_of_line, opening_brackets)
    let [closing_bracket_match, _]      = s:BracketMatch(remainder_of_line, closing_brackets)

    if opening_bracket_match < 0 && closing_bracket_match >= 0
      let closing_bracket = closing_brackets[closing_bracket_match]
      if closing_bracket == '>'
        " an unmatched > in this context means comparison do nothing
      else
        " there's an extra closing bracket from outside the list, bail out
        break
      endif
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
        let rem = s:RemainderOfLine()
      endif
    endif

    normal! l
    let remainder_of_line = s:RemainderOfLine()
  endwhile

  let &whichwrap = original_whichwrap
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

function! s:FunctionReturnType()
  let found_result = search(')\_s\+->\_s\+\%(\k\|::\)*Result\>', 'Wbn')
  let found_option = search(')\_s\+->\_s\+\%(\k\|::\)*Option\>', 'Wbn')

  if found_result <= 0 && found_option <= 0
    return ''
  elseif found_result > found_option
    return 'Result'
  elseif found_option > found_result
    return 'Option'
  else
    return ''
  endif
endfunction
