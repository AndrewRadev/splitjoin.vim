function! sj#jsx#SplitSelfClosingTag()
  if s:noTagUnderCursor()
    return 0
  endif

  let tag = sj#GetMotion('va<')
  if tag == '' || tag !~ '^<\k'
    return 0
  endif

  " is it self-closing?
  if tag !~ '/>$'
    return 0
  endif

  let tag_name = matchstr(tag, '^<\zs\k[^>/[:space:]]*')
  let replacement = substitute(tag, '\s*/>$', '>\n</'.tag_name.'>', '')
  call sj#ReplaceMotion('va<', replacement)
  return 1
endfunction

" Needs to be called with the cursor on a starting or ending tag to work.
function! sj#jsx#JoinHtmlTag()
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

  if body == ''
    " then there's no contents, let's turn it into a self-closing tag
    let tag_name = matchstr(tag, '^<\zs\k[^>/[:space:]]*')
    let self_closing_tag = substitute(tag, '>\_s\+</\s*'.tag_name.'\s*>$', ' />', '')

    if self_closing_tag == tag
      " then the substitution failed for some reason
      return 0
    endif

    call sj#ReplaceMotion('vat', self_closing_tag)
  else
    let body = join(sj#TrimList(split(body, "\n")), ' ')
    call sj#ReplaceMotion('vit', body)
  end

  return 1
endfunction

function! s:noTagUnderCursor()
  return searchpair('<', '', '>', 'cb', '', line('.')) <= 0
        \ && searchpair('<', '', '>', 'c', '', line('.')) <= 0
endfunction
