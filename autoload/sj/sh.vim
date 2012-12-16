function! sj#sh#SplitBySemicolon()
  let line = getline('.')

  if line !~ ';'
    return 0
  endif

  let body = join(split(line, ';\s*'), "\n")
  call sj#ReplaceMotion('V', body)
  return 1
endfunction

function! sj#sh#JoinWithSemicolon()
  if !nextnonblank(line('.') + 1)
    return 0
  endif

  s/;\=\s*\n\_s*/; /e
  return 1
endfunction
