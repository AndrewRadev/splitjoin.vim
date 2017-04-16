function! sj#rust#SplitMatchClause()
  if !sj#SearchUnderCursor('^.*\s*=>\s*.*$')
    return 0
  endif

  call search('=>\s*\zs.', 'W', line('.'))

  let start_col = col('.')
  if !search(',\s*\%(//.*\)\=$', 'W', line('.'))
    return 0
  endif
  let comma_col = col('.')
  let end_col = comma_col - 1

  let body = sj#GetCols(start_col, end_col)
  call sj#ReplaceCols(start_col, comma_col, "{\n".body."\n},")
  return 1
endfunction

function! sj#rust#JoinMatchClause()
  if !sj#SearchUnderCursor('^.*\s*=>\s*{\s*$')
    return 0
  endif

  call search('=>\s*\zs{', 'W', line('.'))

  let body = sj#Trim(sj#GetMotion('Vi{'))
  if stridx(body, "\n") >= 0
    return 0
  endif

  call sj#ReplaceMotion('Va{', body)
  return 1
endfunction
