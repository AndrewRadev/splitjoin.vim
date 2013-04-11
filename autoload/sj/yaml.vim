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
  let line_no    = line('.')
  let line       = getline(line_no)
  let whitespace = s:GetIndentWhitespace(line_no)

  if line !~ ':\s*\(#.*\)\?$' || line_no + 1 > line('$')
    " then there's nothing to join
    return 0
  else
    let [lines, last_line_no] = s:GetChildren(line_no)

    if empty(lines) || lines[0] !~ '^\s*-'
      return 0
    end

    let lines       = map(lines, 'sj#Trim(substitute(v:val, "^\\s*-", "", ""))')
    let lines       = filter(lines, 'v:val !~ "^\s*$"')
    let first_line  = substitute(line, '\s*#.*$', '', '')
    let replacement = first_line.' ['.join(lines, ', ').']'

    call sj#ReplaceLines(line_no, last_line_no, replacement)
    silent! normal! zO
    call s:SetIndentWhitespace(line_no, whitespace)

    return 1
  endif
endfunction

function! sj#yaml#SplitMap()
  let [from, to] = sj#LocateBracesOnLine('{', '}')

  if from < 0 && to < 0
    return 0
  else
    let line_no    = line('.')
    let whitespace = s:GetIndentWhitespace(line_no)
    let pairs      = sj#ParseJsonObjectBody(from + 1, to - 1)
    let body       = "\n".join(pairs, "\n")

    call sj#ReplaceMotion('Va{', body)
    silent! normal! zO
    call s:SetIndentWhitespace(line_no, whitespace)
    call s:IncreaseIndentWhitespace(line_no + 1, line_no + len(pairs), whitespace)
    exe line_no.'s/\s*$//e'

    if g:splitjoin_align
      let body_start = line_no + 1
      let body_end   = body_start + len(pairs) - 1
      call sj#Align(body_start, body_end, 'json_object')
    endif

    return 1
  endif
endfunction

function! sj#yaml#JoinMap()
  let line_no    = line('.')
  let line       = getline(line_no)
  let whitespace = s:GetIndentWhitespace(line_no)

  if line !~ '\k\+:\s*$' || line_no + 1 > line('$')
    return 0
  else
    let [lines, last_line_no] = s:GetChildren(line_no)
    let lines = sj#TrimList(lines)

    if g:splitjoin_normalize_whitespace
      let lines = map(lines, 'substitute(v:val, ":\\s\\+", ": ", "")')
    endif

    let replacement = sj#Trim(line) . ' { '. join(lines, ', ') . ' }'

    call sj#ReplaceLines(line_no, last_line_no, replacement)
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

function! s:GetChildren(line_no)
  let line_no      = a:line_no
  let next_line_no = line_no + 1
  let indent       = indent(line_no)
  let next_line    = getline(next_line_no)

  while next_line_no <= line('$') &&
        \ (sj#BlankString(next_line) || indent(next_line_no) > indent)
    let next_line_no = next_line_no + 1
    let next_line    = getline(next_line_no)
  endwhile
  let next_line_no = next_line_no - 1

  return [sj#GetLines(line_no + 1, next_line_no), next_line_no]
endfunction
