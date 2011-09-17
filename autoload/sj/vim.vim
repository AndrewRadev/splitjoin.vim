function! sj#vim#Split()
  return 0
endfunction

function! sj#vim#Join()
  let next_line_no = line('.') + 1

  if next_line_no > line('$')
    return 0
  endif

  let next_line = getline(next_line_no)
  if next_line =~ '^\s*\\'
    normal! j0f\xk
    join
    call sj#vim#Join()
    return 1
  else
    return 0
  endif
endfunction
