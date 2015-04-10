function! sj#php#SplitBraces()
  let bracedpattern = '(\(.*\))'
  let line         = getline('.')

  if line !~? bracedpattern
    return 0
  else
    let [from, to] = sj#LocateBracesOnLine('(', ')')

    if from < 0 && to < 0
      return 0
    else
      let pairs = sj#ParseJsonObjectBody(from + 1, to - 1)

      if len(pairs) <= 1
        return 0
      endif

      let body  = "(\n".join(pairs, ",\n")."\n)"
      call sj#ReplaceMotion('Va(', body)

      let body_start = line('.') + 1
      let body_end   = body_start + len(pairs)

      call sj#PushCursor()
      exe "normal! jV".(body_end - body_start)."j2="
      call sj#PopCursor()

      if g:splitjoin_align
        call sj#Align(body_start, body_end, 'hashrocket')
      endif
    endif

    return 1
  endif
endfunction

function! sj#php#JoinBraces()
  let line = getline('.')

  if line !~ '(\s*$'
    return 0
  endif

  call search('(\s*$', 'ce', line('.'))

  let body = sj#GetMotion('Vi(')

  if g:splitjoin_normalize_whitespace
    let body = substitute(body, '\s*=>\s*', ' => ', 'g')
  endif
  let body = join(sj#TrimList(split(body, "\n")), ' ')
  call sj#ReplaceMotion('Va(', '('.body.')')

  return 1
endfunction

function! sj#php#JoinHtmlTags()
  if synIDattr(synID(line("."), col("."), 1), "name") =~ '^php'
    " then we're in php, don't try to join tags
    return 0
  else
    return sj#html#JoinTags()
  endif
endfunction

function! sj#php#SplitIfClause()
  let pattern = '\<if\s*(.\{-})\s*{.*}'

  if search(pattern, 'Wbc', line('.')) <= 0
    return 0
  endif

  normal! f(
  normal %
  normal! f{

  let body = sj#GetMotion('Va{')
  let body = substitute(body, '^{\s*\(.\{-}\)\s*}$', "{\n\\1\n}", '')
  call sj#ReplaceMotion('Va{', body)

  return 1
endfunction

function! sj#php#JoinIfClause()
  let pattern = '\<if\s*(.\{-})\s*{\s*$'

  if search(pattern, 'Wbc', line('.')) <= 0
    return 0
  endif

  normal! f(
  normal %
  normal! f{

  let body = sj#GetMotion('Va{')
  let body = substitute(body, "\\s*\n\\s*", ' ', 'g')
  call sj#ReplaceMotion('Va{', body)

  return 1
endfunction

function! sj#php#SplitPhpMarker()
  if sj#SearchUnderCursor('<?=\=\%(php\)\=.\{-}?>') <= 0
    return 0
  endif

  let start_col = col('.')
  let skip = sj#SkipSyntax('phpStringSingle', 'phpStringDouble', 'phpComment')
  if sj#SearchSkip('?>', skip, 'We', line('.')) <= 0
    return 0
  endif
  let end_col = col('.')

  let body = sj#GetCols(start_col, end_col)
  let body = substitute(body, '^<?\(=\=\%(php\)\=\)\s*', "<?\\1\n", '')
  let body = substitute(body, '\s*?>$', "\n?>", '')

  call sj#ReplaceCols(start_col, end_col, body)
  return 1
endfunction

function! sj#php#JoinPhpMarker()
  if sj#SearchUnderCursor('<?=\=\%(php\)\=\s*$') <= 0
    return 0
  endif

  let start_lineno = line('.')
  let skip = sj#SkipSyntax('phpStringSingle', 'phpStringDouble', 'phpComment')
  if sj#SearchSkip('?>', skip, 'We') <= 0
    return 0
  endif
  let end_lineno = line('.')

  let saved_joinspaces = &joinspaces
  set nojoinspaces
  exe start_lineno.','.end_lineno.'join'
  let &joinspaces = saved_joinspaces

  return 1
endfunction
