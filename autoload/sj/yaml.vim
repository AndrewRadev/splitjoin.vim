function! sj#yaml#SplitArray()
  return 0
endfunction

function! sj#yaml#JoinArray()
  let line_no      = line('.')
  let line         = getline(line_no)
  let next_line_no = line_no + 1
  let indent       = indent(line_no)

  if line !~ ':\s*\(#.*\)\?$' || next_line_no > line('$')
    " then there's nothing to join
    return 0
  else
    let next_line = getline(next_line_no)

    if next_line !~ '^\s*-'
      return 0
    endif

    while next_line_no <= line('$') &&
          \ (sj#BlankString(next_line) || indent(next_line_no) > indent)
      let next_line_no = next_line_no + 1
      let next_line    = getline(next_line_no)
    endwhile
    let next_line_no = next_line_no - 1

    let lines       = sj#GetLines(line_no + 1, next_line_no)
    let lines       = map(lines, 'sj#Trim(substitute(v:val, "^\\s*-", "", ""))')
    let first_line  = substitute(line, '\s*#.*$', '', '')
    let replacement = first_line.' ['.join(lines, ', ').']'

    call sj#ReplaceLines(line_no, next_line_no, replacement, { 'indent': 0 })

    return 1
  endif
endfunction
