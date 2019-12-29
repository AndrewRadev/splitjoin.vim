function! sj#yaml#SplitArray()
  let [line, line_no, whitespace] = s:readCurrentLine()

  let prefix     = ''
  let array_part = ''
  let indent     = 1
  let end_offset = 0

  let nestedExp = '\v^\s*((-\s+)+)(\[.*\])$'

  " Split arrays which are map properties
  " E.g.
  "   prop: [1, 2]
  if s:stripComment(line) =~ ':\s*\[.*\]$'
    let [key, array_part] = s:splitKeyValue(line)
    let prefix            = key . ":\n"

  " Split nested arrays
  " E.g.
  "   - [1, 2]
  elseif s:stripComment(line) =~ nestedExp
    let prefix     = substitute(line, nestedExp, '\1', '')
    let array_part = substitute(line, nestedExp, '\3', '')
    let indent     = len(substitute(line, '\v[^-]', '', 'g'))
    let end_offset = -1
  endif

  if array_part != ''
    let body        = substitute(array_part, '\v^\s*\[(.*)\]\s*$', '\1', '')
    let array_items = s:splitArrayBody(body)

    call sj#ReplaceMotion('V', prefix . '- ' . join(array_items, "\n- "))
    silent! normal! zO
    call s:SetIndentWhitespace(line_no, whitespace)
    call s:IncreaseIndentWhitespace(line_no + 1, line_no + len(array_items) + end_offset, whitespace, indent)

    return 1
  endif

  return 0
endfunction

function! sj#yaml#JoinArray()
  let [line, line_no, whitespace] = s:readCurrentLine()

  let lines = []
  let first_line  = s:stripComment(line)

  let nestedExp = '\v^(\s*(-\s+)+)(-\s+.*)$'

  if s:stripComment(line) =~ nestedExp && s:isValidLineNo(line_no)
    let [lines, last_line_no] = s:GetChildren(line_no)
    let lines = [substitute(first_line, nestedExp, '\3', '')] + lines
    let first_line = sj#Rtrim(substitute(first_line, nestedExp, '\1', ''))
  endif

  if s:stripComment(line) =~ ':$' && s:isValidLineNo(line_no + 1)
    let [lines, last_line_no] = s:GetChildren(line_no)
  endif


  if !empty(lines) && lines[0] =~ '^\s*-'
    let lines       = map(lines, 'sj#Trim(substitute(v:val, "^\\s*-", "", ""))')
    let lines       = filter(lines, '!sj#BlankString(v:val)')
    let replacement = first_line.' ['.s:joinArrayItems(lines).']'

    call sj#ReplaceLines(line_no, last_line_no, replacement)
    silent! normal! zO
    call s:SetIndentWhitespace(line_no, whitespace)

    return 1
  endif

  " then there's nothing to join
  return 0
endfunction

function! sj#yaml#SplitMap()
  let [from, to] = sj#LocateBracesOnLine('{', '}')

  if from >= 0 && to >= 0
    let [line, line_no, whitespace] = s:readCurrentLine()
    let pairs      = sj#ParseJsonObjectBody(from + 1, to - 1)
    let body       = join(pairs, "\n")

    let indent_level = 0
    let end_offset   = -1

    " Increase indention if the map is inside a nested array.
    " E.g.
    "   - - { one: 1 }
    if line =~ '^\s*-\s'
      let indent_level = s:nestedArrayLevel(line)
    endif

    " Move body into next line if it is a map property.
    " E.g.
    "   prop: { one: 1 }
    "   - prop: { one: 1 }
    if line =~ '^\v\s*(-\s+)*.*:\s\{.*'
      let body          = "\n" . body
      let indent_level += 1
      let end_offset    = 0
    endif

    call sj#ReplaceMotion('Va{', body)
    silent! normal! zO
    call s:SetIndentWhitespace(line_no, whitespace)
    call s:IncreaseIndentWhitespace(line_no + 1, line_no + len(pairs) + end_offset, whitespace, indent_level)
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
      let [item, rest] = s:readArray(char . rest)
      call add(items, sj#Trim(item))

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

"
" '[]'
" '[1, 2]'
" '[[1, 2]]'
function! s:readArray(str)

  let array = ''
  let rest  = sj#Ltrim(a:str)

  if rest[0] == '['
    let [arrayEnd, rest] = s:readArray(rest[1:])
    let array = '[' . arrayEnd . ']'

    return [array, rest]
  endif

  let [item, rest] = s:readUntil(rest, ']')

  return [sj#Trim(item), rest]
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

  let first_char = line[0]

  let key   = ''
  let value = ''

  " Read line starts with a fenced string. E.g
  "   'one': 1
  "   'one'
  if first_char == '"' || first_char == "'"
    let [item, rest] = s:readUntil(line[1:], first_char)
    let key          = first_char . item . first_char
    let [_, value]   = s:readUntil(rest, ':')
    " TODO throw if invalid? E.g. 'foo':1
  else
    let parts = split(line . ' ', ': ')
    let [key, value] = [parts[0], join(parts[1:], ': ')]
  endif

  if value == '' && a:line !~ '\s*:$'
    let value = key
    let key   = ''
  endif

  return [sj#Trim(key), sj#Trim(value)]
endfunction

" Calculate the nesting level of an array item
" E.g.
"   - foo    => 1
"   - - bar  => 2
function! s:nestedArrayLevel(line)
  let prefix = substitute(a:line, '^\s*((-\s+)+).*', '\1', '')
  let levels = substitute(prefix, '[^-]', '', 'g')
  return len(levels)
endfunction
