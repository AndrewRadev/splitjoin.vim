let s:edge = '->'
" node regexp unused
let s:node = '\("*[^\"]\{-}"\|\i\+\)'

function! sj#dot#ExtractNodes(side)
  " Just split on comma
  " FIXME will fail on \" , \"
  let nodes = split(a:side, ',')
  return sj#TrimList(nodes)
endfunction

function! sj#dot#SplitStatements()
  " FIXME use proper regex
  let statements = split(getline('.'), ';')
  if len(statements) < 2 | return 0 | endif
  call map(statements, 'v:val . ";"')
  call sj#ReplaceMotion('V', join(statements, "\n"))
  return 1
endfunction

function! sj#dot#JoinStatements()
  " unused
  normal! J
endfunction

function! sj#dot#SplitEdges()
  " split multi statement if possible
  if sj#dot#SplitStatements() | return 0 | endif

  let line = getline('.')
  " chop off potential trailing ;
  let statement = split(line, ';')[-1]
  " Split to elements of an edge
  let sides = split(statement, s:edge) 
  if len(sides) < 2
    return 0
  endif

  let [edges, idx] = [[], 0]
  while idx < len(sides) - 1
    " handling of chained expressions
    " such as A -> B -> C
    let edges += [[sj#dot#ExtractNodes(get(sides, idx)),
          \ sj#dot#ExtractNodes(get(sides, idx + 1))]]
    let idx = idx + 1
  endwhile

  let new_edges = []
  for edge in edges
    let [lhs, rhs] = edge
    for source_node in lhs
      for dest_node in rhs
        let new_edges += [source_node . ' ' . s:edge . ' ' . dest_node . ';']
      endfor
    endfor
  endfor
  let body = join(new_edges, "\n")
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
  " TODO apply some sort of matching algorithm
  return sj#dot#JoinStatements()
endfunction
