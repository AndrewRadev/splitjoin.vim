function! sj#html#SplitTags()
  let line = getline('.')
  let tag_regex = '\(<.\{-}>\)\(.*\)\(<\/.\{-}>\)'
  let tag_with_content_regex = '\(<.\{-}>\)\(.\+\)\(<\/.\{-}>\)'

  if line =~ tag_regex
    let body = sj#GetMotion('Vat')
    if line =~ tag_with_content_regex
      call sj#ReplaceMotion('Vat', substitute(body, tag_regex, '\1\n\2\n\3', ''))
    else
      call sj#ReplaceMotion('Vat', substitute(body, tag_regex, '\1\n\3', ''))
    endif
    return 1
  else
    return 0
  endif
endfunction

" Needs to be called with the cursor on a starting or ending tag to work.
function! sj#html#JoinTags()
  if s:noTagUnderCursor()
    return 0
  endif

  let tag = sj#GetMotion('vat')
  let body = sj#GetMotion('vit')

  if len(split(tag, "\n")) == 1
    " then it's just one line, ignore
    return 0
  endif

  let body = sj#Trim(body)
  let body = join(sj#TrimList(split(body, "\n")), ' ')

  call sj#ReplaceMotion('vit', body)

  return 1
endfunction

function! sj#html#SplitAttributes()
  let lineno = line('.')
  let line = getline('.')

  " Check if we are really on a single tag line
  if search('^\s*<', 'bcWe', line('.')) <= 0
    return 0
  endif
  let start = col('.')

  if search('>\s*$', 'W', line('.')) <= 0
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

  call sj#ReplaceMotion('V', body)

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

  " Check if we are on a tag of splitted attributes
  if !(line =~ '^\s*<' && line !~ '>\s*$')
    return 0
  endif

  let start = line('.')
  let end   = search('>\s*$', 'W')

  let lines = sj#GetLines(start, end)
  let joined = join(sj#TrimList(lines), ' ')
  let joined = substitute(joined, '\s*>$', '>', '')

  call sj#ReplaceLines(start, end, indent . joined)

  return 1
endfunction

function! s:noTagUnderCursor()
  return searchpair('<', '', '>', 'cb', '', line('.')) <= 0
        \ && searchpair('<', '', '>', 'c', '', line('.')) <= 0
endfunction

function! s:withIndentation(str, indent)
  return repeat(' ', a:indent) . a:str
endfunction
