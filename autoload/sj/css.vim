function! sj#css#SplitDefinition()
  if !s:LocateDefinition()
    return 0
  endif

  if getline('.') !~ '{.*}' " then there's nothing to split
    return 0
  endif

  let body = sj#GetMotion('Vi{')

  let lines = split(body, ";\s*")
  let lines = sj#TrimList(lines)
  let lines = filter(lines, 'v:val !~ "^\s*$"')

  let body = join(lines, ";\n") . ";"

  call sj#ReplaceMotion('Va{', "{\n".body."\n}")

  if g:splitjoin_align
    let alignment_start = line('.') + 1
    let alignment_end   = alignment_start + len(lines) - 1
    call sj#Align(alignment_start, alignment_end, 'css_declaration')
  endif

  return 1
endfunction

function! sj#css#JoinDefinition()
  if !s:LocateDefinition()
    return 0
  endif

  if getline('.') =~ '{.*}' " then there's nothing to join
    return 0
  endif

  let body = sj#GetMotion('Vi{')

  let lines = split(body, ";\\?\s*\n")
  let lines = sj#TrimList(lines)
  let lines = filter(lines, 'v:val !~ "^\s*$"')
  if g:splitjoin_normalize_whitespace
    let lines = map(lines, "substitute(v:val, '\\s*:\\s\\+', ': ', '')")
  endif

  let body = join(lines, "; ")
  let body = substitute(body, ';\?$', ';', '')
  let body = substitute(body, '{;', '{', '')

  call sj#ReplaceMotion('Va{', '{ '.body.' }')

  return 1
endfunction

function! sj#css#JoinMultilineSelector()
  let line = getline('.')

  let start_line = line('.')
  let end_line   = start_line
  let col        = col('.')
  let limit_line = line('$')

  while !sj#BlankString(line) && line !~ '{\s*$' && end_line < limit_line
    call cursor(end_line + 1, col)
    let end_line = line('.')
    let line     = getline('.')
  endwhile

  if start_line == end_line
    return 0
  else
    if line =~ '^\s*{\s*$'
      let end_line = end_line - 1
    endif

    exe start_line.','.end_line.'join'
    return 1
  endif
endfunction

function! sj#css#SplitMultilineSelector()
  if getline('.') !~ '.*,.*{\s*$'
    " then there is nothing to split
    return 0
  endif

  let definition = getline('.')
  let replacement = substitute(definition, ',\s*', ",\n", 'g')

  call sj#ReplaceMotion('V', replacement)

  return 1
endfunction

function! s:LocateDefinition()
  if search('{', 'bcW', line('.')) <= 0 && search('{', 'cW', line('.')) <= 0
    return 0
  else
    return 1
  endif
endfunction
