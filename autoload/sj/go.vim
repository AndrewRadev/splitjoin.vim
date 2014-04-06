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

function! sj#go#SplitStruct()
  let [start, end] = sj#LocateBracesOnLine('{', '}', 'goString', 'goComment')
  if start < 0 && end < 0
    return 0
  endif

  let args = sj#ParseJsonObjectBody(start + 1, end - 1)
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
    call add(arguments, argument)
  endfor

  call sj#ReplaceMotion('va{', '{'.join(arguments, ', ').'}')
  return 1
endfunction
