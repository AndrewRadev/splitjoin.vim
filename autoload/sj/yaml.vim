function! sj#yaml#SplitArray()
  let line = getline('.')

  if line =~ ':\s*\[.*\]\s*\(#.*\)\?$'
    let [key_part, array_part] = split(line, ':')
    let array_part             = sj#ExtractRx(array_part, '\[\(.*\)\]', '\1')
    let expanded_array         = join(split(array_part, ',\s*'), "\n- ")

    call sj#ReplaceMotion('V', key_part.":\n- ".expanded_array)
    " TODO (2011-09-25) Set proper indent

    return 1
  else
    return 0
  endif
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
