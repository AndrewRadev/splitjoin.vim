function! sj#perl#SplitIfClause()
  let line    = getline('.')
  let pattern = '\(.*\) \(if\|unless\|while\|until\) \(.*\);\s*$'

  if line !~ pattern
    return 0
  endif

  let replacement = substitute(line, pattern, "\\2 (\\3) {\n\\1;\n}", '')
  call sj#ReplaceMotion('V', replacement)

  return 1
endfunction

function! sj#perl#JoinIfClause()
  let current_line      = getline('.')
  let if_clause_pattern = '^\s*\(if\|unless\|while\|until\)\s*(\(.*\))\s*{\s*$'

  if current_line !~ if_clause_pattern
    return 0
  endif

  let condition = substitute(current_line, if_clause_pattern, '\2', '')
  let operation = substitute(current_line, if_clause_pattern, '\1', '')
  let start_line = line('.')

  call search('{', 'W', line('.'))
  if searchpair('{', '', '}', 'W') <= 0
    return 0
  endif

  let end_line = line('.')
  let body     = sj#GetMotion('Vi{')
  let body     = substitute(body, ';\_s*$', '', '')

  let replacement = body.' '.operation.' '.condition.';'
  call sj#ReplaceLines(start_line, end_line, replacement)

  return 1
endfunction
