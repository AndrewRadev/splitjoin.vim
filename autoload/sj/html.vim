function! sj#html#SplitTags()
  let tag_regex = '\(<.\{-}>\)\(.*\)\(<\/.\{-}>\)'
  let lineno = line('.')
  let indent = indent('.')

  let skip = sj#SkipSyntax(['htmlString'])

  if search(tag_regex, 'Wbc', line('.'), 0, skip) <= 0
    return 0
  endif

  let start_col = col('.')
  let tag_name = expand('<cword>')

  call sj#PushCursor()
  normal! %l
  let inner_start_col = col('.')
  call sj#PopCursor()

  if searchpair($'<{tag_name}\>', '', $'</{tag_name}>', 'W', skip, line('.')) <= 0
    return
  endif
  let inner_end_col = col('.') - 1
  let [_, end_col] = searchpos($'</{tag_name}>', 'Wne', line('.'), 0, skip)

  if inner_end_col - inner_start_col > 1
    " There is content inside of the body, insert two newlines
    exe $"normal! {lineno}G{inner_end_col}|a\<cr>"
    exe $"normal! {lineno}G{inner_start_col}|i\<cr>"
  else
    exe $"normal! {lineno}G{inner_start_col}|i\<cr>"
  endif

  call sj#SetIndent(lineno + 1, indent + shiftwidth())

  return 1
endfunction

" Needs to be called with the cursor on a starting or ending tag to work.
function! sj#html#JoinTags()
  if s:noTagUnderCursor()
    return 0
  endif

  let skip = sj#SkipSyntax(['htmlString'])
  let opening_tag = sj#GetMotion('va>')
  let opening_lineno = line('.')
  let tag_name = expand('<cword>')

  if searchpair($'<{tag_name}\>', '', $'</{tag_name}>', 'W', skip) <= 0
    return
  endif
  let closing_lineno = line('.')

  if closing_lineno - opening_lineno == 1
    " No content, just join
    join
    return 1
  endif

  if closing_lineno - opening_lineno < 1
    " Mismatched start and end
    return 0
  endif

  let body_lines = sj#GetLines(opening_lineno + 1, closing_lineno - 1)
  let body_lines = sj#TrimList(body_lines)
  let body = join(body_lines, ' ')

  call sj#ReplaceLines(opening_lineno + 1, closing_lineno - 1, body)
  exe $'keeppatterns {opening_lineno},{opening_lineno + 1}s/\n\_s*//e'

  return 1
endfunction

function! sj#html#SplitAttributes()
  let lineno = line('.')
  let line = getline('.')
  let skip = sj#SkipSyntax(['htmlString'])

  " Check if we are really on a single tag line
  if sj#SearchSkip('<', skip, 'bcWe', line('.')) <= 0
    return 0
  endif
  let start = col('.')

  " Avoid matching =>
  if sj#SearchSkip('\%(^\|[^=]\)\zs>', skip, 'W', line('.')) <= 0
    return 0
  endif
  let end = col('.')

  let result = []
  let indent = indent('.')

  let argparser = sj#argparser#html_args#Construct(start, end, getline('.'))
  call argparser.Process()
  let args = argparser.args

  if len(args) <= 1
    " only one argument would only the tag opener, no attributes
    return 0
  endif

  " The first item contains the tag and needs slightly different handling
  let args[0] = s:withIndentation(args[0], indent)

  if sj#settings#Read('html_attributes_bracket_on_new_line')
    let args[-1] = substitute(args[-1], '\s*/\=>$', "\n\\0", '')
  endif

  if sj#settings#Read('html_attributes_hanging')
    if len(args) <= 2
      " in the hanging case, nothing to split if there's at least one
      " non-opening attribute
      return 0
    endif
    let body = args[0].' '.join(args[1:-1], "\n")
  else
    let body = join(args, "\n")
  endif

  call sj#ReplaceCols(start, end, sj#Trim(body))

  if sj#settings#Read('html_attributes_hanging')
    " For some strange reason, built-in HTML indenting fails here.
    let attr_indent = indent + len(args[0]) + 1
    let start_line = lineno + 1
    let end_line = lineno + len(args[1:-1]) -1

    for l in range(start_line, end_line)
      call setline(l, repeat(' ', attr_indent).sj#Trim(getline(l)))
    endfor
  endif

  return 1
endfunction

function! sj#html#JoinAttributes()
  let line = getline('.')
  let indent = repeat(' ', indent('.'))

  if s:noTagUnderCursor()
    return 0
  endif

  let skip = sj#SkipSyntax(['htmlString'])

  if sj#SearchSkip('<', skip, 'bcW') <= 0
    return 0
  endif
  let start_pos = getpos('.')

  if sj#SearchSkip('\%(^\|[^=]\)\zs>', skip, 'Wc') <= 0
    return 0
  endif
  let end_pos = getpos('.')

  if start_pos[1] == end_pos[1]
    " tag is single-line, nothing to join
    return 0
  endif

  let lines = split(sj#GetByPosition(start_pos, end_pos), "\n")
  let joined = join(sj#TrimList(lines), ' ')
  let joined = substitute(joined, '\s*>$', '>', '')

  call sj#ReplaceByPosition(start_pos, end_pos, joined)
  return 1
endfunction

function! s:noTagUnderCursor()
  return searchpair('<', '', '>', 'cb', '', line('.')) <= 0
        \ && searchpair('<', '', '>', 'c', '', line('.')) <= 0
endfunction

function! s:withIndentation(str, indent)
  return repeat(' ', a:indent) . a:str
endfunction
