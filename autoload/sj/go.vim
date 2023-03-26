let s:eol_pattern = '\s*\%(\/\/.*\)\=$'

function! sj#go#SplitImports()
  if getline('.') =~ '^import ".*"$'
    call sj#Keeppatterns('s/^import \(".*"\)$/import (\r\1\r)/')
    normal! k==
    return 1
  else
    return 0
  endif
endfunction

function! sj#go#JoinImports()
  if getline('.') =~ '^import ($' &&
        \ getline(line('.') + 1) =~ '^\s*".*"$' &&
        \ getline(line('.') + 2) =~ '^)$'
    call sj#Keeppatterns('s/^import (\_s\+\(".*"\)\_s\+)$/import \1/')
    return 1
  else
    return 0
  endif
endfunction

function! sj#go#SplitVars() abort
  let pattern = '^\s*\(var\|type\|const\)\s\+[[:keyword:], ]\+=\='
  if sj#SearchUnderCursor(pattern) <= 0
    return 0
  endif

  call search(pattern, 'Wce', line('.'))
  let line = getline('.')

  if line[col('.') - 1] == '='
    " before and after =
    let lhs = sj#Trim(strpart(line, 0, col('.') - 1))
    let rhs = sj#Ltrim(strpart(line, col('.')))

    let values_parser = sj#argparser#go_vars#Construct(rhs)
    call values_parser.Process()

    let values = values_parser.args
    let comment = values_parser.comment
  else
    let [comment, comment_start, _] = matchstrpos(line, '\s*\%(\/\/.*\)\=$')
    if comment == ""
      let lhs = sj#Trim(line)
    else
      let lhs = sj#Trim(strpart(line, 0, comment_start))
    endif

    let values = []
  endif

  let [prefix, _, prefix_end] = matchstrpos(lhs, '^\s*\(var\|type\|const\)\s\+')
  let lhs = strpart(lhs, prefix_end)
  let variables = split(lhs, ',\s*')

  let declarations = []
  for i in range(0, len(variables) - 1)
    if i < len(values)
      call add(declarations, variables[i] . ' = ' . values[i])
    else
      call add(declarations, variables[i])
    endif
  endfor

  let replacement = prefix . "(\n"
  let replacement .= join(declarations, "\n")
  let replacement .= "\n)"
  if comment != ''
    let replacement .= ' ' . sj#Ltrim(comment)
  endif

  call sj#ReplaceMotion('_vg_', replacement)
  return 0
endfunction

function! sj#go#JoinVars() abort
  let pattern = '^\s*\(var\|type\|const\)\s\+('
  if sj#SearchUnderCursor(pattern.s:eol_pattern) <= 0
    return 0
  endif

  call search(pattern, 'Wce', line('.'))

  let declarations = sj#TrimList(split(sj#GetMotion('vi('), "\n"))
  let variables = []
  let values = []

  for line in declarations
    let [lhs, _, match_end] = matchstrpos(line, '.\{-}\s*=\s*')

    if match_end > -1
      call add(variables, matchstr(lhs, '.\{-}\ze\s*=\s*'))
      call add(values, strpart(line, match_end))
    else
      let line = substitute(line, ',$', '', '')
      call add(variables, line)
    endif
  endfor

  if len(variables) == 0
    return 0
  endif

  let combined_declaration = join(variables, ', ')

  if len(values) > 0
    let combined_declaration .= ' = ' . join(values, ', ')
  endif

  call sj#ReplaceMotion('va(', combined_declaration)
  return 1
endfunction

function! sj#go#SplitStruct()
  let [start, end] = sj#LocateBracesAroundCursor('{', '}', ['goString', 'goComment'])
  if start < 0 && end < 0
    return 0
  endif

  let args = sj#ParseJsonObjectBody(start + 1, end - 1)

  for arg in args
    if arg !~ '^\k\+\s*:'
      " this is not really a struct instantiation
      return 0
    end
  endfor

  call sj#ReplaceCols(start + 1, end - 1, "\n".join(args, ",\n").",\n")
  return 1
endfunction

function! sj#go#JoinStruct()
  let start_lineno = line('.')

  if search('{$', 'Wc', line('.')) <= 0
    return 0
  endif

  normal! %
  let end_lineno = line('.')

  if start_lineno == end_lineno
    " we haven't moved, brackets not found
    return 0
  endif

  let arguments = []
  for line in getbufline('%', start_lineno + 1, end_lineno - 1)
    let argument = substitute(line, ',$', '', '')
    let argument = sj#Trim(argument)

    if argument !~ '^\k\+\s*:'
      " this is not really a struct instantiation
      return 0
    end

    if sj#settings#Read('normalize_whitespace')
      let argument = substitute(argument, '^\k\+\zs:\s\+', ': ', 'g')
    endif

    call add(arguments, argument)
  endfor

  if sj#settings#Read('curly_brace_padding')
    let padding = ' '
  else
    let padding = ''
  endif

  let replacement = '{' . padding . join(arguments, ', ') . padding . '}'
  call sj#ReplaceMotion('va{', replacement)
  return 1
endfunction

function! sj#go#SplitSingleLineCurlyBracketBlock()
  let [start, end] = sj#LocateBracesAroundCursor('{', '}', ['goString', 'goComment'])
  if start < 0 && end < 0
    return 0
  endif

  let body = sj#GetMotion('vi{')
  call sj#ReplaceMotion('va{', "{\n".sj#Trim(body)."\n}")
  return 1
endfunction

function! sj#go#JoinSingleLineFunctionBody()
  let start_lineno = line('.')

  if search('{$', 'Wc', line('.')) <= 0
    return 0
  endif

  normal! %
  let end_lineno = line('.')

  if start_lineno == end_lineno
    " we haven't moved, brackets not found
    return 0
  endif

  if end_lineno - start_lineno > 2
    " more than one line between them, can't join
    return 0
  endif

  normal! va{J
  return 1
endfunction

function! sj#go#SplitFunc()
  let pattern = '^func\%(\s*(.\{-})\s*\)\=\s\+\k\+\zs('
  if search(pattern, 'Wcn', line('.')) <= 0 &&
        \ search(pattern, 'Wbcn', line('.')) <= 0
    return 0
  endif

  let split_type = ''

  let [start, end] = sj#LocateBracesAroundCursor('(', ')', ['goString', 'goComment'])
  if start > 0
    let split_type = 'definition_list'
  else
    let [start, end] = sj#LocateBracesAroundCursor('{', '}', ['goString', 'goComment'])

    if start > 0
      let split_type = 'function_body'
    endif
  endif

  if split_type == 'function_body'
    let contents = sj#Trim(sj#GetCols(start + 1, end - 1))
    call sj#ReplaceCols(start + 1, end - 1, "\n".contents."\n")
    return 1
  elseif split_type == 'definition_list'
    let parsed = sj#ParseJsonObjectBody(start + 1, end - 1)

    " Keep `a, b int` variable groups on the same line
    let arg_groups = []
    let typed_arg_group = ''
    for elem in parsed
      if match(elem, '\s\+') != -1
        let typed_arg_group .= elem
        call add(arg_groups, typed_arg_group)
        let typed_arg_group = ''
      else
        " not typed here, group it with later vars
        let typed_arg_group .= elem . ', '
      endif
    endfor

    call sj#ReplaceCols(start + 1, end - 1, "\n".join(arg_groups, ",\n").",\n")
    return 1
  else
    return 0
  endif
endfunction

function! sj#go#SplitFuncCall()
  let [start, end] = sj#LocateBracesAroundCursor('(', ')', ['goString', 'goComment'])
  if start < 0 && end < 0
    return 0
  endif

  let args = sj#ParseJsonObjectBody(start + 1, end - 1)
  call sj#ReplaceCols(start + 1, end - 1, "\n".join(args, ",\n").",\n")
  return 1
endfunction

function! sj#go#JoinFuncCallOrDefinition()
  let start_lineno = line('.')

  if search('($', 'Wc', line('.')) <= 0
    return 0
  endif

  normal! %
  let end_lineno = line('.')

  if start_lineno == end_lineno
    " we haven't moved, brackets not found
    return 0
  endif

  let arguments = []
  for line in getbufline('%', start_lineno + 1, end_lineno - 1)
    let argument = substitute(line, ',$', '', '')
    let argument = sj#Trim(argument)
    call add(arguments, argument)
  endfor

  let replacement = '(' . join(arguments, ', ') . ')'
  call sj#ReplaceMotion('va(', replacement)
  return 1
endfunction
