let s:skip_syntax = sj#SkipSyntax(['String', 'Comment'])
let s:ending_semicolon_pattern = ';\s*\%(//.*\)\=$'

function! sj#rust#SplitMatchClause()
  if !sj#SearchUnderCursor('^.*\s*=>\s*.*$')
    return 0
  endif

  if !search('=>\s*\zs.', 'W', line('.'))
    return 0
  endif

  let start_col = col('.')
  if !search(',\=\s*\%(//.*\)\=$', 'W', line('.'))
    return 0
  endif

  " handle trailing comma if there is one
  if getline('.')[col('.') - 1] == ','
    let content_end_col = col('.')
    let body_end_col = content_end_col - 1
  else
    let content_end_col = col('.')
    let body_end_col = content_end_col
  endif

  let body = sj#GetCols(start_col, body_end_col)
  call sj#ReplaceCols(start_col, content_end_col, "{\n".body."\n},")
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

  let previous_start_col = -2
  let start_col = -1

  while previous_start_col != start_col
    let previous_start_col = start_col

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
    else
      break
    endif

    if start_col <= 1
      " first character, no previous one
      break
    endif

    " move backwards one step from the start
    let pos = getpos('.')
    let pos[2] = start_col - 1
    call setpos('.', pos)
    let char = getline('.')[col('.') - 1]
  endwhile

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
  if sj#SearchUnderCursor('|.\{-}|\s*\zs{', 'Wc', line('.')) <= 0
    return 0
  endif

  let closure_contents = sj#GetMotion('vi{')
  call sj#ReplaceMotion('va{', "{\n".sj#Trim(closure_contents)."\n}")
  return 1
endfunction

function! sj#rust#SplitExprClosure()
  if !sj#SearchUnderCursor('|.\{-}| [^{]')
    return 0
  endif
  if search('|.\{-}| \zs.', 'W', line('.')) <= 0
    return 0
  endif

  let start_col = col('.')
  let end_col = s:JumpBracketsTill('\%([,;]\|$\)')

  let closure_contents = sj#GetCols(start_col, end_col)
  call sj#ReplaceCols(start_col, end_col, "{\n".closure_contents."\n}")
  return 1
endfunction

function! sj#rust#JoinClosure()
  if !sj#SearchUnderCursor('|.\{-}| {\s*$')
    return 0
  endif
  if search('|.\{-}| \zs{\s*$', 'W', line('.')) <= 0
    return 0
  endif

  " check if we've got an empty block:
  if sj#GetMotion('va{') =~ '^{\_s*}$'
    return 0
  endif

  let closure_contents = sj#Trim(sj#GetMotion('vi{'))
  let lines = sj#TrimList(split(closure_contents, "\n"))

  if len(lines) > 1
    let replacement = '{ '.join(lines, ' ').' }'
  elseif len(lines) == 1
    let replacement = lines[0]
  else
    " No contents, leave nothing inside
    let replacement = ' '
  endif

  call sj#ReplaceMotion('va{', replacement)
  return 1
endfunction

function! sj#rust#SplitCurlyBrackets()
  " in case we're on a struct name, go to the bracket:
  call sj#SearchUnderCursor('\k\+\s*{', 'e')
  " in case we're in an if-clause, go to the bracket:
  call sj#SearchUnderCursor('\<if .\{-}{', 'e')

  let [from, to] = sj#LocateBracesAroundCursor('{', '}')

  if from < 0 && to < 0
    return 0
  endif

  if (to - from) < 2
    " empty {} block
    return 0
  endif

  let body = sj#Trim(sj#GetCols(from + 1, to - 1))
  let prefix = sj#GetCols(0, from - 1)
  let indent = indent(line('.')) + (exists('*shiftwidth') ? shiftwidth() : &sw)

  let parser = sj#argparser#rust#Construct(from + 1, to - 1, getline('.'))
  call parser.Process()
  let args = parser.args
  if len(args) <= 0
    return 0
  endif

  if prefix =~ '^\s*use\s\+\%(\k\+::\)\+\s*$'
    " then it's a module import:
    "   use my_mod::{Alpha, Beta as _, Gamma};
    let imports = map(args, 'v:val.argument')
    let body = join(imports, ",\n")
    if sj#settings#Read('trailing_comma')
      let body .= ','
    endif

    call sj#ReplaceCols(from, to, "{\n".body."\n}")
  elseif parser.IsValidStruct()
    " then it's a
    "
    let is_only_pairs = parser.IsOnlyStructPairs()

    let items = []
    let last_arg = ''
    for arg in args
      let last_arg = arg.argument

      " attributes are not indented, so let's give them appropriate whitespace
      let whitespace = repeat(' ', indent)
      let components = map(copy(arg.attributes), 'whitespace.v:val')

      call add(components, arg.argument)
      call add(items, join(components, "\n"))
    endfor

    let body = join(items, ",\n")
    if sj#settings#Read('trailing_comma')
      if last_arg =~ '^\.\.'
        " interpolated struct, a trailing comma would be invalid
      else
        let body .= ','
      endif
    endif

    call sj#ReplaceCols(from, to, "{\n".body."\n}")

    if is_only_pairs && sj#settings#Read('align')
      let body_start = line('.') + 1
      let body_end   = body_start + len(items) - 1

      if items[-1] =~ '^\.\.'
        " interpolated struct, don't align that one
        let body_end -= 1
      endif

      if body_end - body_start > 0
        call sj#Align(body_start, body_end, 'json_object')
      endif
    endif
  else
    " it's just a normal block, ignore the parsed content
    let body = substitute(body, ';\ze.', ";\n", 'g')
    call sj#ReplaceCols(from, to, "{\n".body."\n}")
  endif

  return 1
endfunction

function! sj#rust#JoinCurlyBrackets()
  let line = getline('.')

  if line !~ '{\s*$'
    return 0
  endif

  call search('{', 'c', line('.'))

  " check if we've got an empty block:
  if sj#GetMotion('va{') =~ '^{\_s*}$'
    return 0
  endif

  let body = sj#GetMotion('Vi{')
  let lines = split(body, "\n")
  let lines = sj#TrimList(lines)

  let body = join(lines, ' ')
  " just in case we're joining a StructName { key: value, }:
  let body = substitute(body, ',$', '', '')

  let in_import = 0
  if line =~ '^\s*use\s\+\%(\k\+::\)\+\s*{$'
    let in_import = 1
  endif
  if !in_import
    let pos = getpos('.')

    " we might still be in a nested import, let's see if we can find it
    while searchpair('{', '', '}', 'Wb', s:skip_syntax, 0, 100) > 0
      if getline('.') =~ '^\s*use\s\+\%(\k\+::\)\+\s*{$'
        let in_import = 1
        break
      endif
    endwhile

    call setpos('.', pos)
  endif

  if in_import
    let body = '{'.body.'}'
  elseif sj#settings#Read('curly_brace_padding')
    let body = '{ '.body.' }'
  else
    let body = '{'.body.'}'
  endif

  if sj#settings#Read('normalize_whitespace')
    let body = substitute(body, '\s\+\k\+\zs:\s\+', ': ', 'g')
  endif

  call sj#ReplaceMotion('Va{', body)
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

function! sj#rust#SplitIfLetIntoMatch()
  let if_let_pattern =  'if\s\+let\s\+\(.*\)\s\+=\s\+\(.\{-}\)\s*{'
  let else_pattern = '}\s\+else\s\+{'

  if search(if_let_pattern, 'We', line('.')) <= 0
    return 0
  endif

  let match_line = substitute(getline('.'), if_let_pattern, "match \\2 {\n\\1 => {", '')
  let body = sj#Trim(sj#GetMotion('vi{'))

  " multiple lines or ends with `;` -> wrap it in a block
  if len(split(body, "\n")) > 1 || body =~ s:ending_semicolon_pattern
    let body = "{\n".body."\n}"
  endif

  " Is there an else clause?
  call sj#PushCursor()
  let else_body = '()'
  normal! %
  if search(else_pattern, 'We', line('.')) > 0
    let else_body = sj#Trim(sj#GetMotion('vi{'))

    " multiple lines or ends with `;` -> wrap it in a block
    if len(split(else_body, "\n")) > 1 || else_body =~ s:ending_semicolon_pattern
      let else_body = "{\n".else_body."\n}"
    endif

    " Delete block, delete rest of line:
    normal! "_da{T}"_D
  endif

  " Back to the if-let line:
  call sj#PopCursor()
  call sj#ReplaceMotion('V', match_line)
  normal! j$
  call sj#ReplaceMotion('Va{', body.",\n_ => ".else_body.",\n}")

  return 1
endfunction

function! sj#rust#JoinEmptyMatchIntoIfLet()
  let match_pattern = 'match\s\+\zs.\{-}\ze\s\+{$'
  let pattern_pattern = '^\s*\zs.\{-}\ze\s\+=>'

  if search(match_pattern, 'We', line('.')) <= 0
    return 0
  endif

  let outer_start_lineno = line('.')

  " find end point
  normal! f{%
  let outer_end_lineno = line('.')

  let inner_start_lineno = search(pattern_pattern, 'Wb', outer_start_lineno)
  if inner_start_lineno <= 0
    return 0
  endif

  let inner_start_lineno = line('.')
  if getline(inner_start_lineno) =~ '^\s*_\s*=>'
    " it's a default match, ignore this one for now
    let inner_start_lineno = search(pattern_pattern, 'Wb', outer_start_lineno)
    if inner_start_lineno <= 0
      return 0
    endif

    if getline(inner_start_lineno) =~ '^\s*_\s*=>'
      " more than one _ => clause?
      return 0
    endif
  endif

  if getline(inner_start_lineno) =~ '{,\=\s*$'
    " it's a block, mark its area:
    exe inner_start_lineno
    normal! 0f{%
    let inner_end_lineno = line('.')
  else
    " not a }, so just one line
    let inner_end_lineno = inner_start_lineno
  endif

  if prevnonblank(inner_start_lineno - 1) != outer_start_lineno
    " the inner start is not immediately after the outer start
    return 0
  endif

  let match_value   = sj#Trim(matchstr(getline(outer_start_lineno), match_pattern))
  let match_pattern = sj#Trim(matchstr(getline(inner_start_lineno), pattern_pattern))

  " currently on inner start, so let's take its contents:
  if inner_start_lineno == inner_end_lineno
    " one-line body, take everything up to the comma
    exe inner_start_lineno
    let body = substitute(getline('.'), '^\s*.\{-}\s\+=>\s*\(.\{-}\),\=\s*$', '\1', '')
  else
    " block body, take everything inside
    let body = sj#Trim(sj#GetMotion('vi{'))
  endif

  " look for an else clause
  call sj#PushCursor()
  exe outer_start_lineno
  let else_body = ''
  if search('^\s*_\s*=>\s*\zs\S', 'W', outer_end_lineno) > 0
    let fallback_value = strpart(getline('.'), col('.') - 1)

    if fallback_value =~ '^{'
      " the else-clause is going to be in a block
      let else_body = sj#Trim(sj#GetMotion('vi{'))
    elseif fallback_value =~ '^()'
      " ignore it
    else
      " one-line value, remove its trailing comma and any comments
      let else_body = substitute(fallback_value, ',\=\s*\%(//.*\)\=$', '', '')
    endif
  endif
  call sj#PopCursor()

  " jump on outer start
  exe outer_start_lineno
  call sj#ReplaceMotion('V', 'if let '.match_pattern.' = '.match_value.' {')
  normal! 0f{
  call sj#ReplaceMotion('va{', "{\n".body."\n}")

  if else_body != ''
    normal! 0f{%
    call sj#ReplaceMotion('V', "} else {\n".else_body."\n}")
  endif

  return 1
endfunction

function! sj#rust#SplitImportList()
  if sj#SearchUnderCursor('^\s*use\s\+\%(\k\+::\)\+{', 'e') <= 0
    return 0
  endif

  let prefix = sj#Trim(strpart(getline('.'), 0, col('.') - 1))
  let body   = sj#GetMotion('vi{')
  let parser = sj#argparser#rust#Construct(1, len(body), body)

  call parser.Process()

  let expanded_imports = []
  for arg in parser.args
    let import = arg.argument

    if import == 'self'
      let expanded_import = substitute(prefix, '::$', ';', '')
    else
      let expanded_import = prefix . import . ';'
    end

    call add(expanded_imports, expanded_import)
  endfor

  if len(expanded_imports) <= 0
    return 0
  endif

  let replacement = join(expanded_imports, "\n")
  call sj#ReplaceMotion('V', replacement)

  return 1
endfunction

function! sj#rust#JoinImportList()
  let import_pattern = '^\s*use\s\+\%(\k\+::\)\+'

  if sj#SearchUnderCursor(import_pattern) <= 0
    return 0
  endif

  let first_import = getline('.')
  let first_import = substitute(first_import, s:ending_semicolon_pattern, '', '')
  let imports = [sj#Trim(first_import)]

  let start_line = line('.')
  let last_line = line('.')
  normal! j

  while sj#SearchUnderCursor(import_pattern) > 0
    if line('.') == last_line
      " we haven't moved, stop here
      break
    endif
    let last_line = line('.')

    let import_line = getline('.')
    let import_line = substitute(import_line, s:ending_semicolon_pattern, '', '')

    call add(imports, sj#Trim(import_line))
    normal! j
  endwhile

  if len(imports) <= 1
    return 0
  endif

  " find common prefix based on first two imports
  let first_prefix_parts  = split(imports[0], '::')
  let second_prefix_parts = split(imports[1], '::')

  if first_prefix_parts[0] != second_prefix_parts[0]
    " no match at all, nothing we can do
    return 0
  endif

  " find only the next ones that match the common prefix
  let common_prefix = ''
  for i in range(1, min([len(first_prefix_parts), len(second_prefix_parts)]) - 1)
    if first_prefix_parts[i] != second_prefix_parts[i]
      let common_prefix = join(first_prefix_parts[:(i - 1)], '::')
      break
    endif
  endfor

  if common_prefix == ''
    if len(imports[0]) > len(imports[1])
      let longer_import  = imports[0]
      let shorter_import = imports[1]
    else
      let longer_import  = imports[1]
      let shorter_import = imports[0]
    endif

    " it hasn't been changed, meaning we completely matched the shorter import
    " within the longer.
    if longer_import == shorter_import
      " they're perfectly identical, just delete the first line and move on
      exe start_line . 'delete'
      return 1
    elseif stridx(longer_import, shorter_import) == 0
      " the shorter is included, consider it a prefix, and we'll puts `self`
      " in there later
      let common_prefix = shorter_import
    else
      " something unexpected went wrong, let's give up
      return 0
    endif
  endif

  let compatible_imports = imports[:1]
  for import in imports[2:]
    if stridx(import, common_prefix) == 0
      call add(compatible_imports, import)
    else
      break
    endif
  endfor

  " Get the differences between the imports
  let differences = []
  for import in compatible_imports
    let difference = strpart(import, len(common_prefix))
    let difference = substitute(difference, '^::', '', '')

    if difference =~ '^{.*}$'
      " there's a list of imports, merge them together
      let parser = sj#argparser#rust#Construct(2, len(difference) - 1, difference)
      call parser.Process()
      for part in map(parser.args, 'v:val.argument')
        call add(differences, part)
      endfor
    elseif len(difference) == 0
      " this is the parent module
      call add(differences, 'self')
    else
      call add(differences, difference)
    endif
  endfor

  if exists('*uniq')
    " remove successive duplicates
    call uniq(differences)
  endif

  let replacement = common_prefix . '::{' . join(differences, ', ') . '};'
  let end_line = start_line + len(compatible_imports) - 1
  call sj#ReplaceLines(start_line, end_line, replacement)

  return 0
endfunction

" Note: special handling for < and >
"
function! s:JumpBracketsTill(end_pattern)
  try
    " ensure we can't go to the next line:
    let saved_whichwrap = &whichwrap
    set whichwrap-=l
    " ensure we can go to the very end of the line
    let saved_virtualedit = &virtualedit
    set virtualedit=onemore

    let opening_brackets = '([<{"'''
    let closing_brackets = ')]>}"'''

    let remainder_of_line = s:RemainderOfLine()
    while remainder_of_line !~ '^'.a:end_pattern
          \ && remainder_of_line !~ '^\s*$'
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
