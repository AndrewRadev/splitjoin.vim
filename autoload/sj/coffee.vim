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
