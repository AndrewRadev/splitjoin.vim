function! sj#perl#SplitIfClause()
  let pattern = '\(.*\) \(if\|unless\|while\|until\) \(.*\);\s*$'

  if g:splitjoin_perl_brace_on_same_line
    let replacement = "\\2 (\\3) {\n\\1;\n}"
  else
    let replacement = "\\2 (\\3) \n{\n\\1;\n}"
  endif

  return s:Split(pattern, replacement)
endfunction

function! sj#perl#JoinIfClause()
  let current_line      = getline('.')
  let if_clause_pattern = '^\s*\(if\|unless\|while\|until\)\s*(\(.*\))\s*{\=\s*$'

  if current_line !~ if_clause_pattern
    return 0
  endif

  let condition = substitute(current_line, if_clause_pattern, '\2', '')
  let operation = substitute(current_line, if_clause_pattern, '\1', '')
  let start_line = line('.')

  call search('{', 'W')
  if searchpair('{', '', '}', 'W') <= 0
    return 0
  endif

  let end_line = line('.')
  let body     = sj#GetMotion('Vi{')
  let body     = join(split(body, ";\\s*\n"), '; ')
  let body     = substitute(body, ';\s\+', '; ', 'g')
  let body     = sj#Trim(body)

  let replacement = body.' '.operation.' '.condition.';'
  call sj#ReplaceLines(start_line, end_line, replacement)

  return 1
endfunction

function! sj#perl#SplitAndClause()
  let pattern = '\(.*\) and \(.*\);\s*$'

  if g:splitjoin_perl_brace_on_same_line
    let replacement = "if (\\1) {\n\\2;\n}"
  else
    let replacement = "if (\\1) \n{\n\\2;\n}"
  endif

  return s:Split(pattern, replacement)
endfunction

function! sj#perl#SplitOrClause()
  let pattern = '\(.*\) or \(.*\);\s*$'

  if g:splitjoin_perl_brace_on_same_line
    let replacement = "unless (\\1) {\n\\2;\n}"
  else
    let replacement = "unless (\\1) \n{\n\\2;\n}"
  endif

  return s:Split(pattern, replacement)
endfunction

function! s:Split(pattern, replacement_pattern)
  let line = getline('.')

  if line !~ a:pattern
    return 0
  endif

  call sj#ReplaceMotion('V', substitute(line, a:pattern, a:replacement_pattern, ''))

  return 1
endfunction
