function! sj#yaml#SplitArray()
  let [line, line_no, whitespace] = s:readCurrentLine()

  let prefix     = ''
  let array_part = ''
  let indent     = 1

  let nestedExp = '\v^\s*((-\s+)+)(\[.*\])$'

  if s:stripComment(line) =~ ':\s*\[.*\]$'
    let [key, array_part] = s:splitKeyValue(line)
    let prefix            = key . ":\n"

  elseif s:stripComment(line) =~ nestedExp
    let prefix     = substitute(line, nestedExp, '\1', '')
    let array_part = substitute(line, nestedExp, '\3', '')
    let indent     = len(substitute(line, '\v[^-]', '', 'g'))
  endif

  if array_part != ''
    let body        = sj#ExtractRx(array_part, '\[\(.*\)\]', '\1')
    let array_items = s:splitArrayBody(body)

    call sj#ReplaceMotion('V', prefix . '- ' . join(array_items, "\n- "))
    silent! normal! zO
    call s:SetIndentWhitespace(line_no, whitespace)
    call s:IncreaseIndentWhitespace(line_no + 1, line_no + len(array_items), whitespace, indent)

    return 1
  endif

  return 0
endfunction

function! sj#yaml#JoinArray()
  let [line, line_no, whitespace] = s:readCurrentLine()

  if s:stripComment(line) =~ ':$' && s:isValidLineNo(line_no + 1)
    let [lines, last_line_no] = s:GetChildren(line_no)

    if !empty(lines) && lines[0] =~ '^\s*-'
      let lines       = map(lines, 'sj#Trim(substitute(v:val, "^\\s*-", "", ""))')
      let lines       = filter(lines, '!sj#BlankString(v:val)')
      let first_line  = s:stripComment(line)
      let replacement = first_line.' ['.s:joinArrayItems(lines).']'

      call sj#ReplaceLines(line_no, last_line_no, replacement)
      silent! normal! zO
      call s:SetIndentWhitespace(line_no, whitespace)

      return 1
    endif
  endif

  " then there's nothing to join
  return 0
endfunction

function! sj#yaml#SplitMap()
  let [from, to] = sj#LocateBracesOnLine('{', '}')

  if !s:isValidLineNo(from) || !s:isValidLineNo(to)
    let [line, line_no, whitespace] = s:readCurrentLine()
    let pairs      = sj#ParseJsonObjectBody(from + 1, to - 1)
    let body       = "\n".join(pairs, "\n")

    let indent_level = 1
    if line =~ '^\s*-\s'
       let indent_level = 2
    endif

    call sj#ReplaceMotion('Va{', body)
    silent! normal! zO
    call s:SetIndentWhitespace(line_no, whitespace)
    call s:IncreaseIndentWhitespace(line_no + 1, line_no + len(pairs), whitespace, indent_level)
    exe line_no.'s/\s*$//e'

    if sj#settings#Read('align')
      let body_start = line_no + 1
      let body_end   = body_start + len(pairs) - 1
      call sj#Align(body_start, body_end, 'json_object')
    endif

    return 1
  endif

  return 0
endfunction

function! sj#yaml#JoinMap()
  let [line, line_no, whitespace] = s:readCurrentLine()

  if line =~ '\k\+:\s*$' && s:isValidLineNo(line_no + 1)
    let [lines, last_line_no] = s:GetChildren(line_no)
    let lines = sj#TrimList(lines)
    let lines = s:normalizeWhitespace(lines)

    let replacement = sj#Trim(line) . ' { '. join(lines, ', ') . ' }'

    call sj#ReplaceLines(line_no, last_line_no, replacement)
    silent! normal! zO
    call s:SetIndentWhitespace(line_no, whitespace)

    return 1
  endif

  return 0
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:readCurrentLine()
  let line_no    = line('.')
  let line       = getline(line_no)
  let whitespace = s:GetIndentWhitespace(line_no)

  return [line, line_no, whitespace]
endfunction

function! s:stripComment(s)
  return substitute(a:s, '\s*#.*$', '', '')
endfunction

function! s:isValidLineNo(no)
  return a:no >= 0  && a:no <= line('$')
endfunction

function! s:normalizeWhitespace(lines)
  if sj#settings#Read('normalize_whitespace')
    return map(a:lines, 'substitute(v:val, ":\\s\\+", ": ", "")')
  endif
  return a:lines
endfunction

function! s:GetIndentWhitespace(line_no)
  return substitute(getline(a:line_no), '^\(\s*\).*$', '\1', '')
endfunction

function! s:SetIndentWhitespace(line_no, whitespace)
  silent exe a:line_no."s/^\\s*/".a:whitespace
endfunction

function! s:IncreaseIndentWhitespace(from, to, whitespace, level)
  if a:whitespace =~ "\t"
    let new_whitespace = a:whitespace . repeat("\t", a:level)
  else
    let new_whitespace = a:whitespace . repeat(' ', &sw * a:level)
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

  while s:isValidLineNo(next_line_no) &&
        \ (sj#BlankString(next_line) || indent(next_line_no) > indent)
    let next_line_no = next_line_no + 1
    let next_line    = getline(next_line_no)
  endwhile
  let next_line_no = next_line_no - 1

  " Preserve trailing empty lines
  while sj#BlankString(getline(next_line_no)) && next_line_no > line_no
    let next_line_no = next_line_no - 1
  endwhile

  return [sj#GetLines(line_no + 1, next_line_no), next_line_no]
endfunction

" Split a string into individual array items.
" E.g.
"   'one, two'               => ['one', 'two']
"   '{ one: 1 }, { two: 2 }' => ['{ one: 1 }', '{ two: 2 }']
function! s:splitArrayBody(body)
  let items = []

  let partial_item = ''
  let rest = sj#Ltrim(a:body)

  while !empty(rest)
    let char = rest[0]
    let rest = rest[1:]

    if char == '{'
      let [item, rest] = s:readUntil(rest, '}')
      call add(items, s:stripCurlyBrackets('{' . item . '}'))

      " skip whitespace and next comma
      let [_, rest] = s:readUntil(sj#Ltrim(rest), ',')
    elseif char == '['
      let [item, rest] = s:readUntil(rest, ']')
      call add(items, sj#Trim('[' + item . ']'))

      " skip whitespace and next comma
      let [_, rest] = s:readUntil(sj#Ltrim(rest), ',')
    elseif char == '"' || char == "'"
      let [item, rest] = s:readUntil(rest, char)
      call add(items, sj#Trim(char . item . char))

      " skip whitespace and next comma
      let [_, rest] = s:readUntil(sj#Ltrim(rest), ',')
    else
      let [item, rest] = s:readUntil(rest, ',')
      call add(items, sj#Trim(char . item))
    endif

    let rest = sj#Ltrim(rest)
  endwhile

  return items
endfunction

function sj#yaml#splitArrayItems(array)
  return s:splitArrayBody(a:array)
endfunction

function sj#yaml#readUntil(str, endChar)
  return s:readUntil(a:str, a:endChar)
endfunction

function! s:readUntil(str, endChar)
  let idx = 0
  while idx < len(a:str)
    let char = a:str[idx]
    if char == a:endChar
      return idx == 0
        \ ? ['', a:str[1:]]
        \ : [a:str[:idx-1], a:str[idx+1:]]
    endif

    let idx += 1
  endwhile

  return [a:str, '']
endfunction

function! s:joinArrayItems(items)
  return join(map(a:items, 's:addCurlyBrackets(v:val)'), ', ')
endfunction

" Add curly brackets if required for joining
" E.g.
"   'one: 1' => '{ one: 1 }'
"   'one'    => 'one'
function! s:addCurlyBrackets(line)
  let line = sj#Trim(a:line)

  if line !~ '^\v\[.*\]$' && line !~ '^\v\{.*\}$'
    let [key, value] = s:splitKeyValue(line)
    if key != ''
      return '{ ' . a:line . ' }'
    endif
  endif

  return a:line
endfunction

" Strip curly brackets if possible
" E.g.
"   '{ one: 1 }'         => 'one: 1'
"   '{ one: 1, two: 2 }' => '{ one: 1, two: 2 }'
function! s:stripCurlyBrackets(item)
  let item = sj#Trim(a:item)

  if item =~ '^{.*}$'
    let parser = sj#argparser#js#Construct(2, len(item) - 1, item)
    call parser.Process()

    if len(parser.args) == 1
      let item = substitute(item, '^{\s*', '', '')
      let item = substitute(item, '\s*}$', '', '')
    endif
  endif

  return item
endfunction

" Split a sting into key and value
" E.g.
"   'one: 1' => ['one', '1']
"   'one'    => ['', 'one']
"   'one:'   => ['one', '']
"   'a:val
function! s:splitKeyValue(line)

  let line = sj#Trim(a:line)
  let parts = []

  let fences = ['"', "'"]

  " Key is a string fenced by " or '
  if line != "" && line =~ '\v^(' . join(fences, '|') . ').*'
    let fence = line[0]
    let expr = '\v^(' . fence . '[^' . fence . ']+' . fence . '):(\s.*)?'

    if line =~ expr
      let parts = [substitute(line, expr, '\1', ''), substitute(line, expr, '\2', '')]
    endif

  else
    let parts = split(line . ' ', ': ')
  endif

  if len(parts) >= 2
    return [sj#Trim(parts[0]), sj#Trim(join(parts[1:], ': '))]
  endif

  " Line does not contain a key value pair
  return ['', a:line]
endfunction

