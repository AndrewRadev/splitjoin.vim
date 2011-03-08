function! sj#ruby#Split()
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
function! sj#ruby#Join()
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
