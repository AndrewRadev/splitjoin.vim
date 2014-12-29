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
  if !(line =~ '^\s*<' && line =~ '>\s*$')
    return 0
  endif

  let result = []
  let indent = indent('.')

  " To handle edge cases, we split at mere spaces first and then
  " look at each item separately
  let split_body = split(line, '\s')

  " The first item contains the tag and needs slightly different handling
  let first = split_body[0]
  let attrs = split_body[1:-1]

  " Add the opening tag with indentation
  call add(result, s:withIndentation(first, indent))

  " Iterate over the attribute list
  let cache = ''
  let inside_attr = 0
  let attr_indent = indent + &shiftwidth
  for attr in attrs
    " a complete attribute
    if attr =~ '=".*"'
      call add(result, s:withIndentation(attr, attr_indent))
    elseif attr =~ '"'
      if inside_attr
        " We've reached the end of an attribute
        let str = s:withIndentation(sj#Trim(cache . ' ' . attr), attr_indent)
        call add(result, str)
        let cache = ''
        let inside_attr = 0
      else
        " We're looking at an attribute, but an incomplete one
        let inside_attr = 1
        let cache = cache . ' ' . attr
      endif
    else
      if inside_attr
        " We're looking at a part of an attribute
        let cache = cache . ' ' . attr
      else
        " We're looking at a plain attribute without an assignment,
        " as in `token` instead of `token="something"`
        call add(result, s:withIndentation(attr, attr_indent))
      endif
    endif
  endfor

  let body = join(result, "\n")
  call sj#ReplaceMotion('V', body)

  return 1
endfunction
