function! sj#coffee#SplitFunction()
  let line = getline('.')

  if line !~ '->'
    return 0
  else
    s/->\s*/->\r/
    normal! ==
    return 1
  endif
endfunction

function! sj#coffee#JoinFunction()
  let line = getline('.')

  if line !~ '->'
    return 0
  else
    s/->\_s\+/-> /
    return 1
  endif
endfunction

function! sj#coffee#SplitIfClause()
  let line            = getline('.')
  let base_indent     = indent('.')
  let suffix_pattern  = '\v(.*\S.*) (if|unless|while|until) (.*)'
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
  let pattern     = '\v^\s*(if|unless|while|until)'

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

function! sj#coffee#SplitObjectLiteral()
  let [from, to] = sj#LocateCurlyBracesOnLine()

  if from < 0 && to < 0
    return 0
  else
    let pairs = s:ParseHash(from + 1, to - 1)
    let body  = "\n".join(pairs, "\n")
    call sj#ReplaceMotion('Va{', body)

    " clean the remaining whitespace
    s/\s\+$//e

    if g:splitjoin_align
      let body_start = line('.') + 1
      let body_end   = body_start + len(pairs) - 1
      call sj#Align(body_start, body_end, 'js_hash')
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

  let lines = getbufline('%', start_line, end_line)
  let lines = map(lines, 'sj#Trim(v:val)')
  if g:splitjoin_normalize_whitespace
    let lines = map(lines, 'substitute(v:val, ":\\s\\+", ": ", "")')
  endif
  let body = getline('.').' { '.join(lines, ', ').' }'
  call sj#ReplaceLines(start_line - 1, end_line, body)

  return 1
endfunction

function! s:ParseHash(from, to)
  let parser = sj#argparser#js#Construct(a:from, a:to, getline('.'))
  call parser.Process()
  return parser.args
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
