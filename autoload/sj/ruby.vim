function! sj#ruby#SplitIfClause()
  let line    = getline('.')
  let pattern = '\v(.*\S.*) (if|unless) (.*)'

  if line =~ pattern
    call sj#ReplaceMotion('V', substitute(line, pattern, '\2 \3\n\1\nend', ''))
    return 1
  else
    return 0
  endif
endfunction

" TODO only works for blocks with a single line for now, e.g.
"
" if foo
"   bar
" end
"
" NOTE only works when the cursor is on the line with the if/unless clause
function! sj#ruby#JoinIfClause()
  let line    = getline('.')
  let pattern = '\v^\s*(if|unless)'

  if line =~ pattern
    normal! jj

    if getline('.') =~ 'end'
      let body = sj#GetMotion('Vkk')

      let [if_line, body, end_line] = split(body, '\n')

      let if_line = sj#Trim(if_line)
      let body    = sj#Trim(body)

      let replacement = body.' '.if_line

      call sj#ReplaceMotion('gv', replacement)

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

    let lines = map(getbufline('.', do_line_no, end_line_no), 'sj#Trim(v:val)')

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
