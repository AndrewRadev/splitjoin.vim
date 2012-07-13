function! sj#ruby#SplitIfClause()
  let line    = getline('.')
  let pattern = '\v(.*\S.*) (if|unless|while|until) (.*)'

  if line =~ pattern
    call sj#ReplaceMotion('V', substitute(line, pattern, '\2 \3\n\1\nend', ''))
    return 1
  else
    return 0
  endif
endfunction

function! sj#ruby#JoinIfClause()
  let line    = getline('.')
  let pattern = '\v^\s*(if|unless|while|until)'

  if line =~ pattern
    let if_line_no = line('.')
    let end_line_pattern = '^'.repeat(' ', indent(if_line_no)).'end\s*$'

    let end_line_no = search(end_line_pattern, 'W')

    if end_line_no > 0
      let lines = sj#GetLines(if_line_no, end_line_no)

      let if_line  = lines[0]
      let end_line = lines[-1]
      let body     = join(lines[1:-2], "\n")

      let if_line = sj#Trim(if_line)
      let body    = sj#Trim(body)
      let body    = s:JoinLines(body)

      let replacement = body.' '.if_line

      call sj#ReplaceLines(if_line_no, end_line_no, replacement)

      return 1
    endif
  endif

  return 0
endfunction

function! sj#ruby#SplitBlock()
  let line    = getline('.')
  let pattern = '\v\{(\s*\|.{-}\|)?\s*(.{-})\s*\}'

  if line =~ pattern
    call search('{', 'bc', line('.'))
    call search('{', 'c', line('.'))

    let body = sj#GetMotion('Va{')
    let body = join(split(body, '\s*;\s*'), "\n")
    let replacement = substitute(body, '^'.pattern.'$', 'do\1\n\2\nend', '')

    call sj#ReplaceMotion('Va{', replacement)

    return 1
  else
    return 0
  endif
endfunction

function! sj#ruby#JoinBlock()
  let do_pattern = '\<do\>\(\s*|.*|\s*\)\?$'

  let do_line_no = search(do_pattern, 'cW', line('.'))
  if do_line_no <= 0
    let do_line_no = search(do_pattern, 'bcW', line('.'))
  endif

  if do_line_no > 0
    let end_line_no = searchpair(do_pattern, '', '\<end\>', 'W')

    let lines = sj#GetLines(do_line_no, end_line_no)
    let lines = sj#TrimList(lines)

    let do_line  = substitute(lines[0], do_pattern, '{\1', '')
    let body     = join(lines[1:-2], '; ')
    let body     = sj#Trim(body)
    let end_line = substitute(lines[-1], 'end', '}', '')

    let replacement = do_line.' '.body.' '.end_line

    call sj#ReplaceLines(do_line_no, end_line_no, replacement)

    return 1
  else
    return 0
  end
endfunction

function! sj#ruby#SplitCachingConstruct()
  let line = getline('.')

  if line =~ '||=' && line !~ '||=\s\+begin\>'
    let replacement = substitute(line, '||=\s\+\(.*\)$', '||= begin\n\1\nend', '')
    call sj#ReplaceMotion('V', replacement)

    return 1
  else
    return 0
  endif
endfunction

function! sj#ruby#JoinCachingConstruct()
  let begin_line = getline('.')
  let body_line  = getline(line('.') + 1)
  let end_line   = getline(line('.') + 2)

  if begin_line =~ '||=\s\+begin' && end_line =~ '^\s*end'
    let lvalue      = substitute(begin_line, '\s\+||=\s\+begin.*$', '', '')
    let body        = sj#Trim(body_line)
    let replacement = lvalue.' ||= '.body

    call sj#ReplaceLines(line('.'), line('.') + 2, replacement)

    return 1
  else
    return 0
  endif
endfunction

function! sj#ruby#JoinHash()
  let line = getline('.')

  if line =~ '{\s*$'
    return s:JoinHashWithCurlyBraces()
  elseif line =~ '(\s*$'
    return s:JoinHashWithRoundBraces()
  elseif line =~ ',\s*$'
    return s:JoinHashWithoutBraces()
  else
    return 0
  endif
endfunction

function! s:JoinHashWithCurlyBraces()
  normal! $

  if g:splitjoin_normalize_whitespace
    let body = sj#GetMotion('Vi{',)
    let body = substitute(body, '\s\+=>\s\+', ' => ', 'g')
    let body = substitute(body, '\s\+\k\+\zs:\s\+', ': ', 'g')
    call sj#ReplaceMotion('Vi{', body)
  endif

  normal! Va{J

  return 1
endfunction

function! s:JoinHashWithRoundBraces()
  normal! $

  let body = sj#GetMotion('Vi(',)
  if g:splitjoin_normalize_whitespace
    let body = substitute(body, '\s*=>\s*', ' => ', 'g')
  endif
  let body = join(sj#TrimList(split(body, "\n")), ' ')
  call sj#ReplaceMotion('Va(', '('.body.')')

  return 1
endfunction

function! s:JoinHashWithoutBraces()
  let start_lineno = line('.')
  let end_lineno   = start_lineno
  let lineno       = nextnonblank(start_lineno + 1)
  let line         = getline(lineno)
  let indent       = repeat(' ', indent(lineno))

  while lineno <= line('$') && ((line =~ '^'.indent && line =~ '=>') || line =~ '^\s*)')
    let end_lineno = lineno
    let lineno     = nextnonblank(lineno + 1)
    let line       = getline(lineno)
  endwhile

  call cursor(start_lineno, 0)
  exe "normal! V".(end_lineno - start_lineno)."jJ"
endfunction

function! sj#ruby#SplitOptions()
  call sj#PushCursor()
  let [from, to] = sj#argparser#ruby#LocateHash()
  call sj#PopCursor()

  if from < 0
    call sj#PushCursor()
    let [from, to, function_type] = sj#argparser#ruby#LocateFunction()
    call sj#PopCursor()

    let option_type = 'option'
  else
    let option_type = 'hash'
  endif

  if from < 0
    return 0
  endif

  let [from, to, args, opts, hash_type] = sj#argparser#ruby#ParseArguments(from, to, getline('.'))

  if len(opts) < 1
    " no options found, leave it as it is
    return 0
  endif

  let replacement = ''

  if len(args) > 0
    let replacement .= join(args, ', ') . ','
  endif
  if !g:splitjoin_ruby_curly_braces && option_type == 'option' && function_type == 'with_round_braces'
    " don't add any opening delimiter, there's a "(" already
  elseif option_type == 'hash' || len(args) == 0
    let replacement .= '{'
  elseif g:splitjoin_ruby_curly_braces
    let replacement .= ' {'
  endif
  let replacement .= "\n"
  let replacement .= join(opts, ",\n")
  if !g:splitjoin_ruby_curly_braces && option_type == 'option' && function_type == 'with_round_braces'
    " add a newline, there's a ")" already
    " Note: adding a space to avoid pasting issues
    let replacement .= "\n "
  elseif g:splitjoin_ruby_curly_braces || option_type == 'hash' || len(args) == 0
    let replacement .= "\n}"
  endif

  call sj#ReplaceCols(from, to, replacement)

  if g:splitjoin_align && hash_type != 'mixed'
    let alignment_start = line('.') + 1
    let alignment_end   = alignment_start + len(opts) - 1

    if hash_type == 'classic'
      call sj#Align(alignment_start, alignment_end, 'hashrocket')
    elseif hash_type == 'new'
      call sj#Align(alignment_start, alignment_end, 'json_object')
    endif
  endif

  return 1
endfunction

" Helper functions

function! s:JoinLines(text)
  let lines = sj#TrimList(split(a:text, "\n"))

  if len(lines) > 1
    return '('.join(lines, '; ').')'
  else
    return join(lines, '; ')
  endif
endfunction
