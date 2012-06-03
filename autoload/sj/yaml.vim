function! sj#yaml#SplitArray()
  let line_no    = line('.')
  let line       = getline(line_no)
  let whitespace = s:GetIndentWhitespace(line_no)

  if line =~ ':\s*\[.*\]\s*\(#.*\)\?$'
    let [key_part, array_part] = split(line, ':')
    let array_part             = sj#ExtractRx(array_part, '\[\(.*\)\]', '\1')
    let expanded_array         = split(array_part, ',\s*')
    let body                   = join(expanded_array, "\n- ")

    call sj#ReplaceMotion('V', key_part.":\n- ".body)
    silent! normal! zO
    call s:SetIndentWhitespace(line_no, whitespace)
    call s:IncreaseIndentWhitespace(line_no + 1, line_no + len(expanded_array), whitespace)

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
  let whitespace   = s:GetIndentWhitespace(line_no)

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
    let lines       = filter(lines, 'v:val !~ "^\s*$"')
    let first_line  = substitute(line, '\s*#.*$', '', '')
    let replacement = first_line.' ['.join(lines, ', ').']'

    call sj#ReplaceLines(line_no, next_line_no, replacement)
    silent! normal! zO
    call s:SetIndentWhitespace(line_no, whitespace)

    return 1
  endif
endfunction

function! s:GetIndentWhitespace(line_no)
  return substitute(getline(a:line_no), '^\(\s*\).*$', '\1', '')
endfunction

function! s:SetIndentWhitespace(line_no, whitespace)
  silent exe a:line_no."s/^\\s*/".a:whitespace
endfunction

function! s:IncreaseIndentWhitespace(from, to, whitespace)
  if a:whitespace =~ "\t"
    let new_whitespace = a:whitespace . "\t"
  else
    let new_whitespace = a:whitespace . repeat(' ', &sw)
  endif

  for line_no in range(a:from, a:to)
    call s:SetIndentWhitespace(line_no, new_whitespace)
  endfor
endfunction
