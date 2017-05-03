let s:edge = '->'
let s:node = '\("*[^\"]\{-}"\|\i\+\)'

function! sj#dot#ExtractNodes(side)
  " Just split on comma
  " FIXME will fail on \" , \"
  return sj#TrimList(split(side, ','))
endfunction

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
  let statements = split(line, ';')
  " Use last statement of a line as heuristic
  " in case there are mor than one
  let sides = split(statements[-1], s:edge) 

  let [edges, idx] = [[], 0]
  while idx < len(sides) - 1
    " handling of chained expressions
    " A -> B -> C
    let edges += [sj#dot#ExtractNodes(get(sides, idx)),
          \ sj#dot#ExtractNodes(get(sides, idx + 1))]
  endwhile
  let new_edges= []
  for edge in edges
    [lhs, rhs] = edge
    for source_node in lhs
      for dest_node in rhs
        let new_edges += [source_node . ' ' . s:edge . ' ' . dest_node . ';']
      endfor
    endfor
  endfor
  let body = join(edges, "\n")
  call sj#ReplaceMotion('V', body)
  return 1
endfunction

function! sj#dot#CompleteMatching(edges)
  " edges should be [src, dst] pairs
  " srcs, dsts = unzip(edges)
  matching = {}
  let all_dest_nodes = []
  for edge in edges
    let [source_node, dest_node] = edge
    matching[source_node] += [dest_node]
    let all_dest_nodes += [dest_node]
  endfor
  for dest_nodes in values(matching)
    " FIXME pseudocode, we actually need set equality
    if dest_nodes != all_dest_nodes
      return 0
    endif
  endfor
  return 1
endfunction

function! sj#dot#JoinEdges()
  " if sj#SearchUnderCursor('[.\{-}]', '') <= 0
  "   return 0
  " endif
  call sj#PushCursor()


  call sj#PopCursor()
  return 1

endfunction
