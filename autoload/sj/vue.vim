function! sj#vue#SplitCssDefinition()
    if GetVueSection() != 'style'
        return 0
    endif
    return sj#css#SplitDefinition()
endfunction

function! sj#vue#JoinCssDefinition()
    if GetVueSection() != 'style'
        return 0
    endif
    return sj#css#JoinDefinition()
endfunction

function! sj#vue#SplitCssMultilineSelector()
    if GetVueSection() != 'style'
        return 0
    endif
    return sj#css#SplitMultilineSelector()
endfunction

function! sj#vue#JoinCssMultilineSelector()
    if GetVueSection() != 'style'
        return 0
    endif
    return sj#css#JoinMultilineSelector()
endfunction

function! GetVueSection()
  let l:startofsection = search('\v^\<(template|script|style)\>', 'bn')
  return substitute(getline(startofsection), '\v[<>]', '', 'g')
endfunction

