function! sj#coffee#SplitFunction()
  let line = getline('.')

  if line !~ '->'
    return 0
  else
    s/->\s*/->\r/
    normal! ==
    return 1
  endif
endfunction

function! sj#coffee#JoinFunction()
  let line = getline('.')

  if line !~ '->'
    return 0
  else
    s/->\_s\+/-> /
    return 1
  endif
endfunction

function! sj#coffee#SplitIfClause()
  let line    = getline('.')
  let pattern = '\v(.*\S.*) (if|unless|while|until) (.*)'

  if line =~ pattern
    call sj#ReplaceMotion('V', substitute(line, pattern, '\2 \3\n\1', ''))
    normal! gv=
    return 1
  else
    return 0
  endif
endfunction

function! sj#coffee#JoinIfClause()
  let line    = getline('.')
  let pattern = '\v^\s*(if|unless|while|until)'

  if line !~ pattern
    return 0
  endif

  let if_clause = sj#Trim(getline('.'))
  let body      = sj#Trim(getline(line('.') + 1))

  call sj#ReplaceMotion('Vj', body.' '.if_clause)
  return 1
endfunction
