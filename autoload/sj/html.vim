function! s:noTagUnderCursor()
  return searchpair('<', '', '>', 'cb', '', line('.')) <= 0
        \ && searchpair('<', '', '>', 'c', '', line('.')) <= 0
endfunction

function! sj#html#SplitTags()
  let line = getline('.')
  let tag_regex = '\(<.\{-}>\)\(.*\)\(<\/.\{-}>\)'

  if line =~ tag_regex
    let body = sj#GetMotion('Vat')
    call sj#ReplaceMotion('Vat', substitute(body, tag_regex, '\1\n\2\n\3', ''))
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

  let body = sj#GetMotion('vit')

  if line("'<") == line("'>")
    " then it's just one line, ignore
    return 0
  endif

  let body = sj#Trim(body)
  let body = join(sj#TrimList(split(body, "\n")), ' ')

  call sj#ReplaceMotion('vit', body)

  return 1
endfunction

function! s:withIndentation(str, indent)
  return repeat(' ', a:indent) . a:str
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

  call sj#ReplaceLines(start, end, indent . joined)

  return 1
endfunction

function! sj#html#SplitAttributes()
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

  if len(args) == 0
    return 0
  endif

  " The first item contains the tag and needs slightly different handling
  let args[0] = s:withIndentation(args[0], indent)

  let body = join(args, "\n")
  call sj#ReplaceMotion('V', body)

  return 1
endfunction
