function! sj#elixir#SplitDef()
  let function_pattern = ',\s*do:'
  let line             = getline('.')

  if line !~ function_pattern
    return 0
  endif

  let line = substitute(line, function_pattern, '\r', '')
  exe 's/'.function_pattern.'/ do\r/'
  call append(line('.'), 'end')
  normal! =2=

  return 1
endfunction

function! sj#elixir#JoinDef()
  let function_pattern = '\s*do\s*\%(#.*\)\=$'
  let def_lineno       = line('.')
  let def_line         = getline(def_lineno)

  if def_line !~ function_pattern
    return 0
  endif

  let body_lineno = line('.') + 1
  let end_lineno  = line('.') + 2

  let body_line = getline(body_lineno)
  let end_line  = getline(end_lineno)

  if end_line !~ '^\s*end$'
    return 0
  endif

  let joined_line = substitute(def_line, function_pattern, ', do: ', '')
  let joined_line = joined_line.sj#Trim(body_line)

  call sj#ReplaceLines(def_lineno, end_lineno, joined_line)
  return 1
endfunction
