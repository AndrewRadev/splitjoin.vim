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
  let pattern = '\v\{(\s*\|.{-}\|)?\s*(.*)\}'

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

    let lines = map(sj#GetLines(do_line_no, end_line_no), 'sj#Trim(v:val)')

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
  let line = getline('.')

  if line =~ '||=\s\+begin'
    let start_line_no    = line('.')
    let end_line_pattern = '^'.repeat(' ', indent(start_line_no)).'end\s*$'
    let end_line_no      = search(end_line_pattern, 'W')

    if end_line_no > 0
      let lines = sj#GetLines(start_line_no, end_line_no)

      let lvalue   = substitute(lines[0], '\s\+||=\s\+begin.*$', '', '')
      let end_line = lines[-1] " unused
      let body     = join(lines[1:-2], "\n")

      let lvalue = sj#Trim(lvalue)
      let body   = sj#Trim(body)
      let body   = s:JoinLines(body)

      let replacement = lvalue.' ||= '.body

      call sj#ReplaceLines(start_line_no, end_line_no, replacement)

      return 1
    endif
  endif

  return 0
endfunction

function! sj#ruby#JoinHash()
  let line    = getline('.')
  let pattern = '{\s*$'

  if line =~ pattern
    normal! $
    normal! Va{J

    return 1
  else
    return 0
  endif
endfunction

function! sj#ruby#SplitOptions()
  call sj#PushCursor()
  let [from, to] = sj#rubyparse#LocateHash()
  call sj#PopCursor()

  if from < 0
    call sj#PushCursor()
    let [from, to] = sj#rubyparse#LocateFunction()
    call sj#PopCursor()
  endif

  if from >= 0
    let [from, to, args, opts] = sj#rubyparse#ParseArguments(from, to, getline('.'))

    if len(opts) < 1
      " no options found, leave it as it is
      return 0
    endif

    let replacement = ''

    if len(args) > 0
      let replacement .= join(args, ', ') . ', '
    endif
    let replacement .= "{\n"
    let replacement .= join(opts, ",\n")
    let replacement .= "\n}"

    call sj#ReplaceCols(from, to, replacement)

    return 1
  else
    return 0
  endif
endfunction

" Helper functions

function! s:JoinLines(text)
  let lines = split(a:text, "\n")
  let lines = map(lines, 'sj#Trim(v:val)')

  if len(lines) > 1
    return '('.join(lines, '; ').')'
  else
    return join(lines, '; ')
  endif
endfunction
