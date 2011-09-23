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
  let continuation_pattern = '^\s*\\'
  let next_line_no         = line('.') + 1
  let next_line            = getline(next_line_no)

  if next_line_no > line('$') || next_line !~ continuation_pattern
    return 0
  else
    while next_line_no <= line('$') && next_line =~ continuation_pattern
      let next_line_no = next_line_no + 1
      let next_line    = getline(next_line_no)
    endwhile

    let range = line('.').','.(next_line_no - 1)
    exe range.'substitute/'.continuation_pattern.'//'
    exe range.'join'

    if g:splitjoin_normalize_whitespace
      call sj#CompressWhitespaceOnLine()
    endif

    return 1
  endif
endfunction
