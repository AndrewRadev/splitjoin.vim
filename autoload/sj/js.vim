function! sj#js#SplitObjectLiteral()
  let [from, to] = sj#LocateBracesAroundCursor('{', '}')

  if from < 0 && to < 0
    return 0
  else
    let pairs = sj#ParseJsonObjectBody(from + 1, to - 1)
    let body = join(pairs, ",\n")
    if sj#settings#Read('trailing_comma')
      let body .= ','
    endif
    let body  = "{\n".body."\n}"
    call sj#ReplaceMotion('Va{', body)

    if sj#settings#Read('align')
      let body_start = line('.') + 1
      let body_end   = body_start + len(pairs) - 1
      call sj#Align(body_start, body_end, 'json_object')
    endif

    return 1
  endif
endfunction

function! sj#js#SplitFunction()
  if expand('<cword>') == 'function' && getline('.') =~ '\<function\>.*(.*)\s*{.*}'
    normal! f{
    return sj#js#SplitObjectLiteral()
  else
    return 0
  endif
endfunction

function! sj#js#JoinObjectLiteral()
  let line = getline('.')

  if line =~ '{\s*$'
    call search('{', 'c', line('.'))
    let body = sj#GetMotion('Vi{')

    let lines = split(body, "\n")
    let lines = sj#TrimList(lines)
    if sj#settings#Read('normalize_whitespace')
      let lines = map(lines, 'substitute(v:val, ":\\s\\+", ": ", "")')
    endif

    let body = join(lines, ' ')
    let body = substitute(body, ',$', '', '')

    if sj#settings#Read('curly_brace_padding')
      let body = '{ '.body.' }'
    else
      let body = '{'.body.'}'
    endif

    call sj#ReplaceMotion('Va{', body)

    return 1
  else
    return 0
  endif
endfunction

function! sj#js#JoinFunction()
  let line = getline('.')

  if line =~ 'function\%(\s\+\k\+\)\=(.*) {\s*$'
    call search('{', 'c', line('.'))
    let body = sj#GetMotion('Vi{')

    let lines = split(body, ';\=\s*\n')
    let lines = sj#TrimList(lines)
    let body = join(lines, '; ').';'
    let body = '{ '.body.' }'

    call sj#ReplaceMotion('Va{', body)

    return 1
  else
    return 0
  endif
endfunction

function! sj#js#SplitArray()
  return s:SplitList(['[', ']'])
endfunction

function! sj#js#SplitArgs()
  return s:SplitList(['(', ')'])
endfunction

function! sj#js#JoinArray()
  return s:JoinList(['[', ']'])
endfunction

function! sj#js#JoinArgs()
  return s:JoinList(['(', ')'])
endfunction

function! sj#js#SplitOneLineIf()
  let line = getline('.')
  if line =~ '^\s*if (.\+) .\+;\?'
    let lines = []
    " use regular vim movements to know where we have to split
    normal! ^w%
    let end_if = getpos('.')[2]
    call add(lines, line[0:end_if] . '{')
    call add(lines, sj#Trim(line[end_if :]))
    call add(lines, '}')

    call sj#ReplaceMotion('V', join(lines, "\n"))

    return 1
  else
    return 0
  endif
endfunction

function! sj#js#JoinOneLineIf()
  let if_line_no = line('.')
  let if_line = getline('.')
  let end_line_no = if_line_no + 2
  let end_line = getline(end_line_no)

  if if_line !~ '^\s*if (.\+) {' || end_line !~ '^\s*}\s*$'
    return 0
  endif

  let body = sj#Trim(getline(if_line_no + 1))
  let new  = if_line[:-2] . body

  call sj#ReplaceLines(if_line_no, end_line_no, new)
  return 1
endfunction

function! s:SplitList(delimiter)
  let start = a:delimiter[0]
  let end   = a:delimiter[1]

  let lineno = line('.')
  let indent = indent('.')

  let [from, to] = sj#LocateBracesOnLine(start, end)

  if from < 0 && to < 0
    return 0
  endif

  let items = sj#ParseJsonObjectBody(from + 1, to - 1)

  if sj#settings#Read('trailing_comma')
    let body  = start."\n".join(items, ",\n").",\n".end
  else
    let body  = start."\n".join(items, ",\n")."\n".end
  endif

  call sj#ReplaceMotion('Va'.start, body)

  " built-in js indenting doesn't indent this properly
  for l in range(lineno + 1, lineno + len(items))
    call sj#SetIndent(l, indent + &sw)
  endfor
  " closing bracket
  let end_line = lineno + len(items) + 1
  call sj#SetIndent(end_line, indent)

  return 1
endfunction

function! s:JoinList(delimiter)
  let start = a:delimiter[0]
  let end   = a:delimiter[1]

  let line = getline('.')

  if line !~ start . '\s*$'
    return 0
  endif

  call search(start, 'c', line('.'))
  let body = sj#GetMotion('Vi'.start)

  let lines = split(body, "\n")
  let lines = sj#TrimList(lines)
  let body  = sj#Trim(join(lines, ' '))
  let body  = substitute(body, ',\s*$', '', '')

  call sj#ReplaceMotion('Va'.start, start.body.end)

  return 1
endfunction

function! sj#js#SplitFatArrowFunction()
  if !sj#SearchUnderCursor('\%((.\{})\|\k\+\)\s*=>\s*.*$')
    return 0
  endif

  call search('\%((.\{})\|\k\+\)\s*=>\s*\zs.*$', 'W', line('.'))

  if strpart(getline('.'), col('.') - 1) =~ '^\s*{'
    " then we have a curly bracket group, easy split:
    let body = sj#GetMotion('vi{')
    call sj#ReplaceMotion('vi{', "\n".sj#Trim(body)."\n")
    return 1
  endif

  let start_col = col('.')
  call s:JumpBracketsTill('[\])};,]')
  let end_col = col('.') - 1

  let body = sj#GetCols(start_col, end_col)
  if getline('.') =~ ';\s*\%(//.*\)\=$'
    let replacement = "{\nreturn ".body.";\n}"
  else
    let replacement = "{\nreturn ".body."\n}"
  endif

  call sj#ReplaceCols(start_col, end_col, replacement)
  return 1
endfunction

function! sj#js#JoinFatArrowFunction()
  if !sj#SearchUnderCursor('\%((.\{})\|\k\+\)\s*=>\s*{\s*$')
    return 0
  endif

  normal! $

  let body = sj#Trim(sj#GetMotion('vi{'))
  let body = substitute(body, '^return\s*', '', '')
  let body = substitute(body, ';$', '', '')
  call sj#ReplaceMotion('va{', body)
  return 1
endfunction

function! s:SearchOpeningBracketOnLine(closing_bracket)
  let skip_expr =
        \ "synIDattr(synID(line('.'),col('.'),1),'name') =~ 'string\\|comment'"
  let bracket_pair = strpart('(){}[]', stridx(')}]', a:closing_bracket) * 2, 2)
  let [lineno, col] = searchpairpos(
        \   escape(bracket_pair[0], '\['), '', bracket_pair[1],
        \   'bWn', skip_expr, line('.')
        \ )
  return col
endfunction

" Note: Duplicated in rust.vim, with some differences
"
function! s:JumpBracketsTill(end_pattern)
  let opening_brackets = '([{"'''
  let closing_brackets = ')]}"'''

  let original_whichwrap = &whichwrap
  set whichwrap+=l

  let remainder_of_line = s:RemainderOfLine()
  while remainder_of_line !~ '^'.a:end_pattern
    let [opening_bracket_match, offset] = s:BracketMatch(remainder_of_line, opening_brackets)
    let [closing_bracket_match, _]      = s:BracketMatch(remainder_of_line, closing_brackets)

    if opening_bracket_match < 0 && closing_bracket_match >= 0
      let closing_bracket = closing_brackets[closing_bracket_match]
      " there's an extra closing bracket from outside the list, bail out
      break
    elseif opening_bracket_match >= 0
      " then try to jump to the closing bracket
      let opening_bracket = opening_brackets[opening_bracket_match]
      let closing_bracket = closing_brackets[opening_bracket_match]

      " first, go to the opening bracket
      if offset > 0
        exe "normal! ".offset."l"
      end

      if opening_bracket == closing_bracket
        " same bracket (quote), search for it, unless it's escaped
        call search('\\\@<!\V'.closing_bracket, 'W', line('.'))
      else
        " different closing, use searchpair
        call searchpair('\V'.opening_bracket, '', '\V'.closing_bracket, 'W', '', line('.'))
        let rem = s:RemainderOfLine()
      endif
    endif

    normal! l
    let remainder_of_line = s:RemainderOfLine()
  endwhile

  let &whichwrap = original_whichwrap
endfunction

function! s:RemainderOfLine()
  return strpart(getline('.'), col('.') - 1)
endfunction

function! s:BracketMatch(text, brackets)
  let index  = 0
  let offset = match(a:text, '^\s*\zs')
  let text   = strpart(a:text, offset)

  for char in split(a:brackets, '\zs')
    if text[0] ==# char
      return [index, offset]
    else
      let index += 1
    endif
  endfor

  return [-1, 0]
endfunction
