let s:skip = sj#SkipSyntax(['pythonString', 'pythonComment'])

function! sj#python#SplitStatement()
  if sj#SearchSkip('^[^:]*\zs:\s*\S', s:skip, '', line('.'))
    s/\%#:\s*/:\r/
    normal! ==
    return 1
  else
    return 0
  endif
endfunction

function! sj#python#JoinStatement()
  if sj#SearchSkip(':\s*$', s:skip, '', line('.')) > 0
    join
    return 1
  else
    return 0
  endif
endfunction

function! sj#python#SplitDict()
  let [from, to] = sj#LocateBracesOnLine('{', '}', ['pythonString'])

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
    for line in range(body_start, body_end + 1)
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

function! sj#python#JoinTuple()
  return s:JoinList('([^)]*\s*$', '(', ')')
endfunction

function! sj#python#SplitImport()
  let import_pattern = '^from \%(.*\) import \zs.*$'

  normal! 0
  if search(import_pattern, 'Wc', line('.')) <= 0
    return 0
  endif

  let import_list = sj#GetMotion('vg_')

  if stridx(import_list, ',') < 0
    return 0
  endif

  let imports = split(import_list, ',\s*')

  call sj#ReplaceMotion('vg_', join(imports, ",\\\n"))
  return 1
endfunction

function! sj#python#JoinImport()
  let import_pattern = '^from \%(.*\) import .*\\\s*$'

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

function! s:SplitList(regex, opening_char, closing_char)
  if sj#SearchUnderCursor(a:regex) <= 0
    return 0
  endif

  call sj#PushCursor()

  " TODO (2012-10-24) connect sj#SearchUnderCursor and sj#LocateBracesOnLine
  normal! l
  let start = col('.')
  normal! h%h
  let end = col('.')

  let items = sj#ParseJsonObjectBody(start, end)

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
