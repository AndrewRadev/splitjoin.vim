function! sj#coffee#SplitFunction()
  let line = getline('.')

  if line !~ '[-=]>'
    return 0
  else
    s/\([-=]\)>\s*/\1>\r/
    normal! ==
    return 1
  endif
endfunction

function! sj#coffee#JoinFunction()
  let line = getline('.')

  if line !~ '[-=]>'
    return 0
  else
    s/\([-=]\)>\_s\+/\1> /
    return 1
  endif
endfunction

function! sj#coffee#SplitIfClause()
  let line            = getline('.')
  let base_indent     = indent('.')
  let suffix_pattern  = '\v(.*\S.*) (if|unless|while|until|for) (.*)'
  let postfix_pattern = '\v(if|unless|while|until) (.*) then (.*)'

  if line =~ suffix_pattern
    call sj#ReplaceMotion('V', substitute(line, suffix_pattern, '\2 \3\n\1', ''))
    call s:SetBaseIndent(line('.'), line('.') + 1, base_indent)
    return 1
  elseif line =~ postfix_pattern
    call sj#ReplaceMotion('V', substitute(line, postfix_pattern, '\1 \2\n\3', ''))
    call s:SetBaseIndent(line('.'), line('.') + 1, base_indent)
    return 1
  else
    return 0
  endif
endfunction

function! sj#coffee#JoinIfClause()
  let line        = getline('.')
  let base_indent = indent('.')
  let pattern     = '\v^\s*(if|unless|while|until|for)\ze\s'

  if line !~ pattern
    return 0
  endif

  let if_clause = sj#Trim(getline('.'))
  let body      = sj#Trim(getline(line('.') + 1))

  if g:splitjoin_coffee_suffix_if_clause
    call sj#ReplaceMotion('Vj', body.' '.if_clause)
  else
    call sj#ReplaceMotion('Vj', if_clause.' then '.body)
  endif
  call s:SetBaseIndent(line('.'), line('.'), base_indent)

  return 1
endfunction

function! sj#coffee#SplitTernaryClause()
  let line = getline('.')
  let pattern = '\v^(.*)if (.*) then (.*) else ([^)]*)(.*)$'

  if line =~ pattern
    let body_when_true  = sj#ExtractRx(line, pattern, '\3')
    let body_when_false = sj#ExtractRx(line, pattern, '\4')
    let replacement     = "if \\2\r\\1".body_when_true."\\5\relse\r\\1".body_when_false."\\5"
    exe 's/'.pattern.'/'.escape(replacement, '/')
    normal! >>kk>>

    return 1
  else
    return 0
  endif
endfunction

function! sj#coffee#SplitObjectLiteral()
  let [from, to] = sj#LocateBracesOnLine('{', '}')

  if from < 0 && to < 0
    return 0
  else
    let pairs = sj#ParseJsonObjectBody(from + 1, to - 1)
    let body  = "\n".join(pairs, "\n")
    call sj#ReplaceMotion('Va{', body)

    " clean the remaining whitespace
    s/\s\+$//e

    if g:splitjoin_align
      let body_start = line('.') + 1
      let body_end   = body_start + len(pairs) - 1
      call sj#Align(body_start, body_end, 'json_object')
    endif

    return 1
  endif
endfunction

function! sj#coffee#JoinObjectLiteral()
  if line('.') == line('$')
    return 0
  endif

  let [start_line, end_line] = s:IndentedLinesBelow('.')

  if start_line == -1
    return 0
  endif

  let lines = sj#GetLines(start_line, end_line)
  let lines = sj#TrimList(lines)
  let lines = map(lines, 'sj#Trim(v:val)')
  if g:splitjoin_normalize_whitespace
    let lines = map(lines, 'substitute(v:val, ":\\s\\+", ": ", "")')
  endif
  let body = getline('.').' { '.join(lines, ', ').' }'
  call sj#ReplaceLines(start_line - 1, end_line, body)

  return 1
endfunction

function! sj#coffee#SplitString()
  if search('["''].\{-}["'']\s*$', 'Wbc', line('.')) <= 0
    return 0
  endif

  let quote       = getline('.')[col('.') - 1]
  let multi_quote = repeat(quote, 2) " Note: only two quotes

  let body     = sj#GetMotion('vi'.quote)
  let new_body = substitute(body, '\\'.quote, quote, 'g')
  let new_body = multi_quote."\n".new_body."\n".multi_quote

  call sj#ReplaceMotion('vi'.quote, new_body)
  normal! j>>

  return 1
endfunction

function! sj#coffee#JoinString()
  if search('\%("""\|''''''\)\s*$', 'Wbc') <= 0
    return 0
  endif
  let start       = getpos('.')
  let multi_quote = expand('<cword>')
  let quote       = multi_quote[0]

  normal! j

  if search(multi_quote, 'Wce') <= 0
    return 0
  endif
  let end = getpos('.')

  let body     = sj#GetByPosition(start, end)
  let new_body = substitute(body, '^'.multi_quote.'\_s*\(.*\)\_s*'.multi_quote.'$', '\1', 'g')
  let new_body = substitute(new_body, quote, '\\'.quote, 'g')
  let new_body = sj#Trim(new_body)
  let new_body = quote.new_body.quote

  call sj#ReplaceByPosition(start, end, new_body)

  return 1
endfunction

function! s:IndentedLinesBelow(line)
  let current_line = line(a:line)
  let first_line   = nextnonblank(current_line + 1)
  let next_line    = first_line
  let base_indent  = indent(current_line)

  if indent(first_line) <= base_indent
    return [-1, -1]
  endif

  while next_line <= line('$') && indent(next_line) > base_indent
    let current_line = next_line
    let next_line    = nextnonblank(current_line + 1)
  endwhile

  return [first_line, current_line]
endfunction

function! s:SetBaseIndent(from, to, indent)
  let current_whitespace = matchstr(getline(a:from), '^\s*')
  let new_whitespace     = repeat(' ', a:indent)

  exe a:from.','.a:to.'s/^'.current_whitespace.'/'.new_whitespace
endfunction
