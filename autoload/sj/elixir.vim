function! sj#elixir#SplitDoBlock()
  let [function_name, function_start, function_end, function_type] =
        \ sj#argparser#elixir#LocateFunction()
  if function_start < 0
    return 0
  endif

  let is_if = function_name == 'if' || function_name == 'unless'

  let parser = sj#argparser#elixir#Construct(function_start, function_end, getline('.'))
  call parser.Process()

  let do_body   = ''
  let else_body = ''
  let args      = []

  for arg in parser.args
    if arg =~ '^do:' && do_body == ''
      let do_body = substitute(arg, '^do:\s*', '', '')
    elseif arg =~ '^else:' && is_if && else_body == ''
      let else_body = substitute(arg, '^else:\s*', '', '')
    else
      call add(args, arg)
    endif
  endfor

  if do_body == ''
    return 0
  endif

  let line = getline('.')

  if is_if && function_type == 'with_round_braces'
    " skip the round brackets before the if-clause
    let new_line = strpart(line, 0, function_start - 2) . ' ' . join(args, ', ')
  else
    let new_line = strpart(line, 0, function_start - 1) . join(args, ', ')
  endif

  if function_end > 0
    if is_if && function_type == 'with_round_braces'
      " skip the round brackets after the if-clause
      let new_line .= strpart(line, function_end + 1)
    else
      let new_line .= strpart(line, function_end)
    end
  else
    " we didn't detect an end, so it goes on to the end of the line
  endif

  if else_body != ''
    let do_block = " do\n" . do_body . "\nelse\n" . else_body . "\nend"
  else
    let do_block = " do\n" . do_body . "\nend"
  endif

  call sj#ReplaceLines(line('.'), line('.'), new_line . do_block)
  return 1
endfunction

function! sj#elixir#JoinDoBlock()
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

  let is_if       = function_name == 'if' || function_name == 'unless'
  let body_lineno = line('.') + 1
  let body_line   = getline(body_lineno)

  if is_if && getline(line('.') + 2) =~ '^\s*else\>'
    let else_lineno = line('.') + 2
    let else_line   = getline(else_lineno)

    let else_body_lineno = line('.') + 3
    let else_body_line   = getline(else_body_lineno)

    let end_lineno = line('.') + 4
    let end_line   = getline(end_lineno)
  else
    let else_line = ''

    let end_lineno = line('.') + 2
    let end_line   = getline(end_lineno)
  endif

  if end_line !~ '^\s*end$'
    return 0
  endif

  exe 'keeppatterns s/'.do_pattern.'//'
  if function_end < 0
    let function_end = col('$') - 1
  endif

  let args = sj#GetCols(function_start, function_end)
  let joined_args = ', do: '.sj#Trim(body_line)
  if else_line != ''
    let joined_args .= ', else: '.sj#Trim(else_body_line)
  endif

  call sj#ReplaceCols(function_start, function_end, args . joined_args)
  exe body_lineno.','.end_lineno.'delete _'
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
