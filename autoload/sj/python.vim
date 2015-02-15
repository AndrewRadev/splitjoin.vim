let s:skip = sj#SkipSyntax('pythonString', 'pythonComment')

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
  let [from, to] = sj#LocateBracesOnLine('{', '}', 'pythonString')

  if from < 0 && to < 0
    return 0
  else
    let pairs = sj#ParseJsonObjectBody(from + 1, to - 1)
    let body  = "{\n".join(pairs, ",\n")."\n}"
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
    if g:splitjoin_normalize_whitespace
      let lines = map(lines, 'substitute(v:val, ":\\s\\+", ": ", "")')
    endif

    let body = join(lines, ' ')

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

  if g:splitjoin_python_brackets_on_separate_lines
    let body = a:opening_char."\n".join(items, ",\n")."\n".a:closing_char
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
  let body = substitute(body, '\s\+'.a:closing_char.'$', a:closing_char, '')

  call sj#ReplaceMotion('va'.a:opening_char, body)

  return 1
endfunction
