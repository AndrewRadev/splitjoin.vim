function! sj#vim#Split()
  if sj#BlankString(getline('.'))
    return 0
  endif

  let new_line = sj#GetMotion('vg_')

  if sj#BlankString(new_line)
    return 0
  else
    let new_line = "\n\\ ".sj#Trim(new_line)
    call sj#ReplaceMotion('vg_', new_line)
    s/\s\+$//e

    return 1
  endif
endfunction

function! sj#vim#Join()
  let continuation_pattern = '^\s*\\'
  let current_lineno       = line('.')
  let next_lineno          = current_lineno + 1
  let next_line            = getline(next_lineno)

  if next_lineno > line('$') || next_line !~ continuation_pattern
    return 0
  else
    exe next_lineno.'s/'.continuation_pattern.'//'
    exe current_lineno.','.next_lineno.'join'

    if g:splitjoin_normalize_whitespace
      call sj#CompressWhitespaceOnLine()
    endif

    return 1
  endif
endfunction
