let s:edge = '->'
let s:node = '\("*[^\"]\{-}"\|\i\+\)'

function! sj#dot#SplitEdges()
  " if sj#SearchUnderCursor('[.\{-}]', '') <= 0
  "   " No split if line contains []
  "   " Just a rough guess to use this function
  "   echom "WARNING"
  "   return 0
  " endif
  let line = getline('.')
  if line !~ s:edge
    return 0
  endif
  let sides = split(getline('.'), s:edge) 
  let lhs = split(get(sides, 0, ''), ',') 
  let rhs = split(get(sides, 1, ''), ',') 
  if len(lhs) < 2 && len(rhs) < 2
    return 0
  endif
  let edges = []
  for source_node in lhs
    for dest_node in rhs
      " TODO more beautiful trimming and readding of spaces here
      let edges += [source_node . s:edge . dest_node]
    endfor
  endfor
  let body = join(edges, "\n")
  call sj#ReplaceMotion('V', body)
  return 1
endfunction

function! sj#dot#JoinEdges()
  " if sj#SearchUnderCursor('[.\{-}]', '') <= 0
  "   return 0
  " endif
  return 1

endfunction
