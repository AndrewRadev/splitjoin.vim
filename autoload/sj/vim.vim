function! sj#vim#Split()
  let new_line = sj#GetMotion('vg_')

  if sj#BlankString(new_line)
    return 0
  else
    let new_line = "\n\\ ".new_line
    call sj#ReplaceMotion('vg_', new_line)

    return 1
  endif
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
