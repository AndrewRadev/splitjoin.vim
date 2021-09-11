function! sj#elixir#SplitDef()
  let [function_name, function_start, function_end, function_type] =
        \ sj#argparser#elixir#LocateFunction()
  if function_start < 0
    return 0
  endif

  let parser = sj#argparser#elixir#Construct(function_start, function_end, getline('.'))
  call parser.Process()
  if len(parser.args) <= 0 || parser.args[-1] !~ '^do:'
    return 0
  endif

  let line = getline('.')
  let args = join(parser.args[0:-2], ', ')
  let new_line = strpart(line, 0, function_start - 1) . args
  if function_end > 0
    let new_line .= strpart(line, function_end)
  else
    " we didn't detect an end, so it goes on to the end of the line
  endif

  let do_body = substitute(parser.args[-1], '^do:\s*', '', '')
  let do_block = " do\n" . do_body . "\nend"

  call sj#ReplaceLines(line('.'), line('.'), new_line . do_block)
  return 1
endfunction

function! sj#elixir#JoinDef()
  let do_pattern = '\s*do\s*\%(#.*\)\=$'
  let def_lineno = line('.')
  let def_line   = getline(def_lineno)

  if def_line !~ do_pattern
    return 0
  endif

  let [function_name, function_start, function_end, function_type] =
        \ sj#argparser#elixir#LocateFunction()
  if function_start < 0
    return 0
  endif

  let body_lineno = line('.') + 1
  let end_lineno  = line('.') + 2

  let body_line = getline(body_lineno)
  let end_line  = getline(end_lineno)

  if end_line !~ '^\s*end$'
    return 0
  endif

  exe 'keeppatterns s/'.do_pattern.'//'
  if function_end < 0
    let function_end = col('$') - 1
  endif
  let args = sj#GetCols(function_start, function_end)
  call sj#ReplaceCols(function_start, function_end, args.', do: '.sj#Trim(body_line))
  exe end_lineno.'delete _'
  exe body_lineno.'delete _'

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
