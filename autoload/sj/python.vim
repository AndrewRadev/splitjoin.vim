let s:skip = sj#SkipSyntax(['pythonString', 'pythonComment', 'pythonStrInterpRegion'])

function! sj#python#SplitStatement()
  if sj#SearchSkip('^[^:]*\zs:\s*\S', s:skip, 'c', line('.'))
    call sj#Keeppatterns('s/\%#:\s*/:\r/')
    normal! ==
    return 1
  else
    return 0
  endif
endfunction

function! sj#python#JoinStatement()
  if sj#SearchSkip(':\s*$', s:skip, 'c', line('.')) > 0
    join
    return 1
  else
    return 0
  endif
endfunction

function! sj#python#SplitDict()
  let [from, to] = sj#LocateBracesAroundCursor('{', '}', ['pythonString'])

  if from < 0 && to < 0
    return 0
  else
    let pairs = sj#ParseJsonObjectBody(from + 1, to - 1)
    let body  = "{\n".join(pairs, ",\n")."\n}"
    if sj#settings#Read('trailing_comma')
      let body = substitute(body, ',\?\n}', ',\n}', '')
    endif
    call sj#ReplaceMotion('Va{', body)

    let body_start = line('.') + 1
    let body_end   = body_start + len(pairs)

    let base_indent = indent('.')
    for line in range(body_start, body_end)
      if base_indent == indent(line)
        " then indentation didn't work quite right, let's just indent it
        " ourselves
        exe line.'normal! >>>>'
      endif
    endfor

    exe body_start.','.body_end.'normal! =='

    return 1
  endif
endfunction

function! sj#python#JoinDict()
  let line = getline('.')

  if line =~ '{\s*$'
    call search('{', 'c', line('.'))
    let body = sj#GetMotion('Vi{')

    let lines = sj#TrimList(split(body, "\n"))
    if sj#settings#Read('normalize_whitespace')
      let lines = map(lines, 'substitute(v:val, ":\\s\\+", ": ", "")')
    endif

    let body = join(lines, ' ')
    if sj#settings#Read('trailing_comma')
      let body = substitute(body, ',\?$', '', '')
    endif

    call sj#ReplaceMotion('Va{', '{'.body.'}')

    return 1
  else
    return 0
  endif
endfunction

function! sj#python#SplitArray()
  return s:SplitList('\[.*]', '[', ']')
endfunction

function! sj#python#JoinArray()
  return s:JoinList('\[[^]]*\s*$', '[', ']')
endfunction

function! sj#python#SplitTuple()
  return s:SplitList('(.\{-})', '(', ')')
endfunction

function! sj#python#SplitArgs()
  if search('\%#[[:keyword:].]\+(', 'e', line('.'))
    return sj#python#SplitTuple()
  endif
endfunction

function! sj#python#JoinTuple()
  return s:JoinList('([^()]*\s*$', '(', ')')
endfunction

function! sj#python#JoinArgs()
  if search('\%#[[:keyword:].]\+(', 'e', line('.'))
    return sj#python#JoinTuple()
  endif
endfunction

function! sj#python#SplitImport()
  let import_pattern = '^\s*from \%(.*\) import \zs.*$'

  normal! 0
  if search(import_pattern, 'Wc', line('.')) <= 0
    return 0
  endif

  let import_lineno = line('.')
  let indent = indent('.')
  let import_list = sj#GetMotion('vg_')

  let imports = split(import_list, ',\s*')
  let import_style = sj#settings#Read('python_import_style')

  if import_style == 'newline_escape'
    " from foo import bar,\
    "   baz
    call sj#ReplaceMotion('vg_', join(imports, ",\\\n"))
  elseif import_style == 'round_brackets'
    " from foo import (
    "   bar,
    "   baz
    " )
    let replacement = join(imports, ",\n")
    if sj#settings#Read('python_brackets_on_separate_lines')
      if sj#settings#Read('trailing_comma')
        let replacement .= ','
      endif
      let replacement = "(\n"..replacement.."\n)"
    else
      let replacement = "("..replacement..")"
    endif
    call sj#ReplaceMotion('vg_', replacement)

    if sj#settings#Read('python_brackets_on_separate_lines')
      " number of imports plus one for the round bracket
      let last_lineno = import_lineno + len(imports) + 1

      call sj#SetIndent(import_lineno + 1, last_lineno - 1, indent + shiftwidth())
      call sj#SetIndent(last_lineno, last_lineno, indent)
    endif
  else
    echoerr "Unknown splitjoin_python_import_style: "..import_style
  endif

  return 1
endfunction

function! sj#python#JoinImportWithNewlineEscape()
  let import_pattern = '^\s*from \%(.*\) import .*\\\s*$'
  if getline('.') !~ import_pattern
    return 0
  endif

  let start_lineno = line('.')
  let current_lineno = nextnonblank(start_lineno + 1)

  while getline(current_lineno) =~ '\\\s*$' && current_lineno < line('$')
    let current_lineno = nextnonblank(current_lineno + 1)
  endwhile

  let end_lineno = current_lineno

  exe start_lineno.','.end_lineno.'s/,\\\n\s*/, /e'
  return 1
endfunction

function! sj#python#JoinImportWithRoundBrackets()
  let import_pattern = '^\s*from \%(.*\) import \zs('
  if search(import_pattern, 'Wc') <= 0
    return 0
  endif

  let import_body = sj#GetMotion('vi(')
  let imports = split(import_body, ',\_s*')
  let replacement = sj#Trim(join(imports, ', '))
  let replacement = substitute(replacement, ',$', '', '')

  call sj#ReplaceMotion('va(', replacement)
  return 1
endfunction

function! sj#python#SplitAssignment()
  if sj#SearchUnderCursor('^\s*\%(\%(\k\|\.\)\+,\s*\)\+\%(\k\|\.\)\+\s*=\s*\S') <= 0
    return 0
  endif

  let variables = split(sj#Trim(sj#GetMotion('vt=')), ',\s*')
  normal! f=
  call search('\S', 'W', line('.'))
  let values = sj#ParseJsonObjectBody(col('.'), col('$'))
  let indent = substitute(getline('.'), '^\(\s*\).*', '\1', '')

  let lines = []

  if len(variables) == len(values)
    let index = 0
    for variable in variables
      call add(lines, indent.variable.' = '.values[index])
      let index += 1
    endfor
  elseif len(values) == 1
    " consider it an array, and index it
    let index = 0
    let array = values[0]
    for variable in variables
      call add(lines, indent.variable.' = '.array.'['.index.']')
      let index += 1
    endfor
  else
    " the sides don't match, let's give up
    return 0
  endif

  call sj#ReplaceMotion('V', join(lines, "\n"))
  if sj#settings#Read('align')
    call sj#Align(line('.'), line('.') + len(lines) - 1, 'equals')
  endif
endfunction

function! sj#python#JoinAssignment()
  let assignment_pattern = '^\s*\%(\k\|\.\)\+\zs\s*=\s*\ze\S'

  if search(assignment_pattern, 'W', line('.')) <= 0
    return 0
  endif

  let start_line = line('.')
  let [first_variable, first_value] = split(getline('.'), assignment_pattern)
  let variables = [ first_variable ]
  let values = [ first_value ]

  let end_line = start_line
  let next_line = line('.') + 1
  while next_line > 0 && next_line <= line('$')
    exe next_line

    if search(assignment_pattern, 'W', line('.')) <= 0
      break
    else
      let [variable, value] = split(getline(next_line), assignment_pattern)
      call add(variables, sj#Trim(variable))
      call add(values, sj#Trim(value))
      let end_line = next_line
      let next_line += 1
    endif

    if v:count > 0 && v:count == (end_line - start_line + 1)
      " stop at the user-provided count
      break
    endif
  endwhile

  if len(variables) <= 1
    return 0
  endif

  if len(values) > 1 && values[0] =~ '\[0\]$'
    " it might be an array, so we could simplify it
    let is_array = 1
    let index = 1
    let array_name = substitute(values[0], '\[0\]$', '', '')
    for value in values[1:]
      if value !~ '^'.array_name.'\s*\['.index.'\]'
        let is_array = 0
        break
      endif
      let index += 1
    endfor

    if is_array
      " the entire right-hand side can be just one item
      let values = [ array_name ]
    endif
  endif

  let body = join(variables, ', ').' = '.join(values, ', ')
  call sj#ReplaceLines(start_line, end_line, body)
  return 1
endfunction

function! sj#python#SplitTernaryAssignment()
  if getline('.') !~ '^\s*\%(\k\|\.\)\+\s*=\s*\S'
    return 0
  endif

  normal! 0
  let include_syntax = sj#IncludeSyntax(['pythonConditional'])

  if sj#SearchSkip('\<if\>', include_syntax, 'W', line('.')) <= 0
    return 0
  endif
  let if_col = col('.')

  if sj#SearchSkip('\<else\>', include_syntax, 'W', line('.')) <= 0
    return 0
  endif

  let else_col = col('.')
  let line     = getline('.')

  let assignment_if_true = trim(strpart(line, 0, if_col - 1))
  let if_clause          = trim(strpart(line, if_col - 1, else_col - if_col))
  let body_if_false      = trim(strpart(line, else_col + len('else')))

  let assignment_prefix   = matchstr(assignment_if_true, '\%(\k\|\.\)\+\s*=')
  let assignment_if_false = assignment_prefix . ' ' . body_if_false

  let indent      = repeat(' ', shiftwidth())
  let base_indent = repeat(' ', indent(line('.')))

  let body = join([
        \   base_indent . if_clause . ':',
        \   base_indent . indent . assignment_if_true,
        \   base_indent . 'else:',
        \   base_indent . indent . assignment_if_false,
        \ ], "\n")
  call sj#ReplaceMotion('V', body)

  return 1
endfunction

function! sj#python#JoinTernaryAssignment()
  let include_syntax = sj#IncludeSyntax(['pythonConditional'])
  let start_lineno = line('.')
  let indent = indent('.')
  normal! 0

  if sj#SearchSkip('^\s*\zsif\>', include_syntax, 'Wc', line('.')) <= 0
    return 0
  endif
  let if_line = trim(getline('.'))
  if if_line !~ ':$'
    return 0
  endif
  let if_clause = strpart(if_line, 0, len(if_line) - 1)

  if search('^\s*\zs\%(\k\|\.\)\+\s*=\s*\S', 'Wc', line('.') + 1) <= 0
    return 0
  endif
  let assignment_if_true = trim(getline('.'))
  let lhs_if_true = matchstr(assignment_if_true, '^\s*\zs\%(\k\|\.\)\+\s*=')
  let body_if_true = trim(strpart(assignment_if_true, len(lhs_if_true)))

  if sj#SearchSkip('^\s*\zselse:', include_syntax, 'Wc', line('.') + 2) <= 0
    return 0
  endif
  let else_line = trim(getline('.'))
  if else_line !~ ':$'
    return 0
  endif

  if search('^\s*\zs\%(\k\|\.\)\+\s*=\s*\S', 'Wc', line('.') + 3) <= 0
    return 0
  endif
  let assignment_if_false = trim(getline('.'))
  let lhs_if_false = matchstr(assignment_if_false, '^\s*\zs\%(\k\|\.\)\+\s*=')
  let body_if_false = trim(strpart(assignment_if_false, len(lhs_if_false)))

  if lhs_if_true != lhs_if_false
    return 0
  endif

  let body = lhs_if_true . ' ' . body_if_true . ' ' . if_clause . ' else ' . body_if_false
  call sj#ReplaceLines(start_lineno, start_lineno + 3, body)
  call sj#SetIndent(start_lineno, start_lineno, indent)

  return 1
endfunction

function! sj#python#SplitString()
  let char = getline('.')[col('.') - 1]
  if char != '"' && char != "'"
    return 0
  endif

  let string_pattern       = '\(\%(^\|[^\\]\)\zs\([''"]\)\).\{-}[^\\]\+\2'
  let empty_string_pattern = '\%(''''\|""\)'

  let lineno = line('.')

  let [match_start, match_end] = sj#SearchColsUnderCursor(string_pattern)
  if match_start <= 0
    let [match_start, match_end] = sj#SearchColsUnderCursor(empty_string_pattern)
    if match_start <= 0
      return 0
    endif
  endif

  let string    = sj#GetCols(match_start, match_end - 1)
  let delimiter = string[0]
  let body      = string[1:-2]
  let indent    = indent(lineno)

  if body =~ '^[''"]$'
    " our body is a single quote, we're trying to split a triple-quoted string
    return 0
  endif

  if body =~ '^\(''''\s*''''\|""\s*""\)$'
    if search('\(''''\zs\s*''''\|""\zs\s*""\)', 'W', line('.')) <= 0
      return 0
    endif

    if delimiter == '"'
      call sj#ReplaceMotion('va"', "\"\n\"")
    elseif delimiter == "'"
      call sj#ReplaceMotion("va'", "'\n'")
    else
      return 0
    endif

    return 1
  endif

  if body =~ '^\(''''\|""\)\S'
    " then the string is already triple-quoted, just replace the insides
    if search('\(''''\|""\)\zs\S', 'W', line('.')) <= 0
      return 0
    endif

    if delimiter == '"'
      let inner_body = sj#GetMotion('vi"')
      call sj#ReplaceMotion('vi"', "\n"..inner_body.."\n")
    elseif delimiter == "'"
      let inner_body = sj#GetMotion("vi'")
      call sj#ReplaceMotion("vi'", "\n"..inner_body.."\n")
    else
      return 0
    endif

    call sj#SetIndent(lineno + 1, lineno + 1, indent + shiftwidth())
    return 1
  endif

  if delimiter == '"'
    if len(body) == 0
      call sj#ReplaceMotion('vi"', '"""'.."\n"..'"""')
    else
      let body = substitute(body, '\\"', '"', 'g')
      call sj#ReplaceMotion('vi"', '""'.."\n"..body.."\n".'""')
    endif
  elseif delimiter == "'"
    if len(body) == 0
      call sj#ReplaceMotion("vi'", "'''\n'''")
    else
      let body = substitute(body, "\\''", "'", 'g')
      call sj#ReplaceMotion("vi'", "''\n"..body.."\n''")
    endif
  else
    return 0
  endif

  if len(body) == 0
    call sj#SetIndent(lineno + 1, lineno + 1, indent)
  else
    call sj#SetIndent(lineno + 1, lineno + 1, indent + shiftwidth())
    call sj#SetIndent(lineno + 2, lineno + 2, indent)
  endif

  return 1
endfunction

function! sj#python#JoinMultilineString()
  if sj#SearchUnderCursor('\("""\|''''''\)\s*$') <= 0
    return 0
  endif

  let start_lineno = line('.')
  let prefix       = getline('.')[0            : col('.') - 2]
  let delimiter    = getline('.')[col('.') - 1 : col('.') + 2]

  if search('^\s*'.delimiter, 'W') <= 0
    return 0
  endif

  let end_lineno = line('.')
  let suffix     = matchstr(getline(end_lineno), '^\s*'.delimiter.'\zs.*\ze')

  if end_lineno - start_lineno > 1
    let lines = sj#GetLines(start_lineno + 1, end_lineno - 1)
    let lines = sj#TrimList(lines)
    let body  = join(lines, " ")
  else
    let body = ''
  endif

  if delimiter == '"""'
    let quote = '"'
    let body = escape(body, '"')
  elseif delimiter == "'''"
    let quote = "'"
    let body = escape(body, "'")
  else
    return 0
  endif

  let replacement = prefix..quote..body..quote..suffix
  call sj#ReplaceLines(start_lineno, end_lineno, replacement)

  return 1
endfunction

function! s:SplitList(regex, opening_char, closing_char)
  let [from, to] = sj#LocateBracesAroundCursor(a:opening_char, a:closing_char, ['pythonString'])
  if from < 0 && to < 0
    return 0
  endif

  call sj#PushCursor()

  let items = sj#ParseJsonObjectBody(from + 1, to - 1)
  if len(items) < 1
    call sj#PopCursor()
    return 0
  endif

  if sj#settings#Read('python_brackets_on_separate_lines')
    if sj#settings#Read('trailing_comma')
      let body = a:opening_char."\n".join(items, ",\n").",\n".a:closing_char
    else
      let body = a:opening_char."\n".join(items, ",\n")."\n".a:closing_char
    endif
  else
    let body = a:opening_char.join(items, ",\n").a:closing_char
  endif

  call sj#PopCursor()
  call sj#ReplaceMotion('va'.a:opening_char, body)
  return 1
endfunction

function! s:JoinList(regex, opening_char, closing_char)
  if sj#SearchUnderCursor(a:regex) <= 0
    return 0
  endif

  let body = sj#GetMotion('va'.a:opening_char)
  let body = substitute(body, '\_s\+', ' ', 'g')
  let body = substitute(body, '^'.a:opening_char.'\s\+', a:opening_char, '')
  if sj#settings#Read('trailing_comma')
    let body = substitute(body, ',\?\s\+'.a:closing_char.'$', a:closing_char, '')
  else
    let body = substitute(body, '\s\+'.a:closing_char.'$', a:closing_char, '')
  endif

  call sj#ReplaceMotion('va'.a:opening_char, body)

  return 1
endfunction

function! sj#python#SplitListComprehension()
  for [opening_char, closing_char] in [['(', ')'], ['[', ']'], ['{', '}']]
    let [from, to] = sj#LocateBracesAroundCursor(opening_char, closing_char, ['pythonString'])
    if from > 0 && to > 0
      break
    endif
  endfor

  if from < 0 && to < 0
    return 0
  endif

  if to - from < 2
    " empty list
    return 0
  endif

  " Start after the opening bracket
  let pos = getpos('.')
  let pos[2] = from + 1
  call setpos('.', pos)

  let break_columns = []
  let include_syntax = sj#IncludeSyntax(['pythonRepeat', 'pythonConditional'])

  while sj#SearchSkip('\<\%(for\|if\)\>', include_syntax, 'W', line('.')) > 0
    call add(break_columns, col('.') - from)
  endwhile

  if len(break_columns) <= 0
    return 0
  endif

  let body = sj#GetMotion('vi' .. opening_char)
  let parts = []
  let last_break = 0

  for break_column in break_columns
    let part = strpart(body, last_break, break_column - last_break - 1)
    call add(parts, sj#Trim(part))
    let last_break = break_column - 1
  endfor

  let part = strpart(body, last_break, to - last_break - 1)
  call add(parts, sj#Trim(part))

  if sj#settings#Read('python_brackets_on_separate_lines')
    let body = opening_char .. "\n" .. join(parts, "\n") .. "\n" .. closing_char
  else
    let body = opening_char .. join(parts, "\n") .. closing_char
  endif

  call sj#ReplaceMotion('va' .. opening_char, body)
  return 1
endfunction
