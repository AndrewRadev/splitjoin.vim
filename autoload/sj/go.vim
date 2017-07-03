function! sj#go#SplitImports()
  if getline('.') =~ '^import ".*"$'
    s/^import \(".*"\)$/import (\r\1\r)/
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
    s/^import (\_s\+\(".*"\)\_s\+)$/import \1/
    return 1
  else
    return 0
  endif
endfunction

function! sj#go#SplitVars()
  if getline('.') =~ '^\(var\|type\|const\) \k\+ .*$'
    s/^\(var\|type\|const\) \(\k\+ .*\)$/\1 (\r\2\r)/
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
    s/^\(var\|type\|const\) (\_s\+\(\k\+ .*\)\_s\+)$/\1 \2/
    return 1
  else
    return 0
  endif
endfunction

function! sj#go#SplitStruct()
  return s:splitStructOrFuncCall('{', '}')
endfunction

function! sj#go#JoinStruct()
  return s:joinStructOrFunc('{', '}')
endfunction

function! sj#go#SplitFunc()
  let pattern = '^func\%(\s*(.\{-})\s*\)\=\s\+\k\+\zs('
  if search(pattern, 'Wc', line('.')) <= 0 &&
        \ search(pattern, 'Wbc', line('.')) <= 0
    return 0
  endif

  let start = col('.')
  if searchpair('(', '', ')', 'W', sj#SkipSyntax(['goString', 'goComment']), line('.')) <= 0
    return 0
  endif
  let end = col('.')

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
endfunction

function! sj#go#JoinFuncCallOrDefinition()
  return s:joinStructOrFunc('(', ')')
endfunction

function! sj#go#SplitFuncCall()
  return s:splitStructOrFuncCall('(', ')')
endfunction

function! s:splitStructOrFuncCall(openBrace, closeBrace)
  let [start, end] = sj#LocateBracesAroundCursor(a:openBrace, a:closeBrace, ['goString', 'goComment'])
  if start < 0 && end < 0
    return 0
  endif

  let args = sj#ParseJsonObjectBody(start + 1, end - 1)
  call sj#ReplaceCols(start + 1, end - 1, "\n".join(args, ",\n").",\n")
  return 1
endfunction

function! s:joinStructOrFunc(openBrace, closeBrace)
  let start_lineno = line('.')

  if search(a:openBrace.'$', 'Wc', line('.')) <= 0
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

  call sj#ReplaceMotion('va'.a:openBrace, a:openBrace . join(arguments, ', ') . a:closeBrace)
  return 1
endfunction
