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

function! sj#elixir#SplitArray()
  let [from, to] = sj#LocateBracesAroundCursor('[', ']', [
        \ 'elixirInterpolationDelimiter',
        \ 'elixirString',
        \ 'elixirStringDelimiter',
        \ 'elixirSigilDelimiter',
        \ ])

  if from < 0
    return 0
  endif

  let items = sj#ParseJsonObjectBody(from + 1, to - 1)

  if len(items) == 0 || to - from < 2
    return 1
  endif

  " substitute [1, 2, | tail]
  let items[-1] = substitute(items[-1], "\\(|[^>].*\\)", "\n\\1", "")

  let body = "[\n" . join(items, ",\n") . "\n]"

  call sj#ReplaceMotion('Va[', body)

  return 1
endfunction

function! sj#elixir#JoinArray()
  normal! $

  if getline('.')[col('.') - 1] != '['
    return 0
  endif

  let body = sj#Trim(sj#GetMotion('Vi['))
  " remove trailing comma
  let body = substitute(body, ',\ze\_s*$', '', '')

  let items = split(body, ",\s*\n")

  if len(items) == 0
    return 1
  endif

  " join isolated | tail on the last line
  let items[-1] = substitute(items[-1], "[[:space:]]*\\(|[^>].*\\)", " \\1", "")

  let body = join(sj#TrimList(items), ', ')
  call sj#ReplaceMotion('Va[', '['.body.']')

  return 1
endfunction
