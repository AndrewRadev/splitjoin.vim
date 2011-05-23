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
  let pattern = '\v\{(\s*\|.*\|)?\s*(.*)\}'

  if line =~ pattern
    let body = sj#ExtractRx(line, pattern, '\2')
    let body = join(split(body, '\s*;\s*'), "\n")
    let replacement = substitute(line, pattern, 'do\1\n'.body.'\nend', '')

    call sj#ReplaceMotion('V', replacement)

    return 1
  else
    return 0
  endif
endfunction

function! sj#ruby#JoinBlock()
  call search('\<do\>\(\s*\|.*\|\s*\)\?$', 'cW', line('.'))
  let do_line_no = search('\<do\>\(\s*\|.*\|\s*\)\?$', 'bcW', line('.'))

  if do_line_no > 0
    let end_line_no = searchpair('\<do\>', '', '\<end\>', 'W')

    let lines = map(sj#GetLines(do_line_no, end_line_no), 'sj#Trim(v:val)')

    let do_line  = substitute(lines[0], 'do', '{', '')
    let body     = join(lines[1:-2], '; ')
    let body     = sj#Trim(body)
    " ignore end line, not needed

    let replacement = do_line.' '.body.' }'

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

function! sj#ruby#SplitHash()
  let line    = getline('.')
  let pattern = '\v\{\s*(([^,]+\s*\=\>\s*[^,]{-1,},?)+)\s*\}[,)]?'

  if line =~ pattern
    call search('{', 'c', line('.'))
    call searchpair('{', '', '}', 'c', line('.'))

    let body  = sj#GetMotion('Vi{')
    let lines = s:SplitHash(body)
    call sj#ReplaceMotion('Va{', "{\n".join(lines, "\n")."\n}")

    return 1
  else
    return 0
  endif
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
  let function_start = sj#rubyparse#LocateFunctionStart()
  call sj#PopCursor()

  if function_start > 0
    let [from, to, args, opts] = sj#rubyparse#ParseArguments(function_start)

    if len(opts) < 1
      " no options found, leave it as it is
      return 0
    endif

    let args = map(args, 'sj#Trim(v:val)')
    let opts = map(opts, 'sj#Trim(v:val)')

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
  end
endfunction

" Helper functions

function! s:SplitHash(string)
  let body = sj#Trim(a:string)."\n"

  let nested_hash_pattern = '\(^[^,]\+=>\s*{.\{-}}[,\n]\)'
  let regular_pattern     = '\(^[^,]\+=>.\{-}[,\n]\)'

  let lines = []

  " TODO correctly handle nested hashes for more than two levels

  while body !~ '^\s*$'
    if body =~ nested_hash_pattern
      let segment = sj#ExtractRx(body, nested_hash_pattern, '\1')
    elseif body =~ regular_pattern
      let segment = sj#ExtractRx(body, regular_pattern, '\1')
    else
      " TODO should never happen, raise error?
      break
    end

    call add(lines, sj#Trim(segment))
    let body = strpart(body, len(segment))
  endwhile

  return lines
endfunction

function! s:JoinLines(text)
  let lines = split(a:text, "\n")
  let lines = map(lines, 'sj#Trim(v:val)')

  if len(lines) > 1
    return '('.join(lines, '; ').')'
  else
    return join(lines, '; ')
  endif
endfunction

function! s:AddBraces(pos)
  let from = a:pos[2]

  normal! $
  call search('\v.\s+do\s*', 'b', line('.'))
  call search('\v.\s+\{\s*\|.*\|.*$', 'b', line('.'))
  call search('\v.(\)$|\)\s)', 'b', line('.'))

  if &filetype == 'eruby'
    call search('.\s\+-\?%>', 'b', line('.'))
  end

  let to = virtcol('.')

  exe "normal! ".to."|"
  exe "normal! a }"
  exe "normal! ".from."|"
  exe "normal! i{ "
endfunction
