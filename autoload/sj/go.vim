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

function! sj#go#SplitVars()
  if getline('.') =~ '^\(var\|type\|const\) \k\+ .*$'
    call sj#Keeppatterns('s/^\(var\|type\|const\) \(\k\+ .*\)$/\1 (\r\2\r)/')
    normal! k==
    return 1
  else
    return 0
  endif
endfunction

function! sj#go#JoinVars()
  if getline('.') =~ '^\(var\|type\|const\) ($' &&
        \ getline(line('.') + 1) =~ '^\s*\k\+ .*$' &&
        \ getline(line('.') + 2) =~ '^)$'
    call sj#Keeppatterns('s/^\(var\|type\|const\) (\_s\+\(\k\+ .*\)\_s\+)$/\1 \2/')
    return 1
  else
    return 0
  endif
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
