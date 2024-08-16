let s:skip_syntax = sj#SkipSyntax(['String', 'Comment'])
let s:eol_pattern = '\s*\%(//.*\)\=$'

function! sj#hare#SplitQuestionMark()
  if sj#SearchSkip('.?', s:skip_syntax, 'Wc', line('.')) <= 0
    return 0
  endif

  let current_line = line('.')
  let end_col = col('.')
  let question_mark_col = col('.') + 1
  let char = getline('.')[end_col - 1]

  let previous_start_col = -2
  let start_col = -1

  while previous_start_col != start_col
    let previous_start_col = start_col

    if char =~ '\k'
      call search('\k\+?;', 'bWc', line('.'))
      let start_col = col('.')
    elseif char == '}'
      " go to opening bracket
      normal! %
      let start_col = col('.')
    elseif char == ')'
      " go to opening bracket
      normal! %
      " find first method-call char
      call search('\%(\k\|\.\|::\)\+!\?(', 'bWc')

      if line('.') != current_line
        " multiline expression, let's just ignore it
        return 0
      endif

      let start_col = col('.')
    else
      break
    endif

    if start_col <= 1
      " first character, no previous one
      break
    endif

    " move backwards one step from the start
    let pos = getpos('.')
    let pos[2] = start_col - 1
    call setpos('.', pos)
    let char = getline('.')[col('.') - 1]
  endwhile

  let expr = sj#GetCols(start_col, end_col)

  let replacement = join([
        \   "match (".expr.") {",
        \   "case error => abort();",
        \   "case let t: type =>",
        \   "	yield t;",
        \   "}"
        \ ], "\n")

  call sj#ReplaceCols(start_col, question_mark_col, replacement)
  return 1
endfunction
