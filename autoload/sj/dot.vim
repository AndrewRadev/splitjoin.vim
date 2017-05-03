let s:edge = '->'
" node regexp unused
let s:node = '\("*[^\"]\{-}"\|\i\+\)'

" Helper functions {{{
function! sj#dot#ExtractNodes(side)
  " Split multiple nodes into single elements
  " Just split on comma
  " FIXME will fail on \" , \"
  let nodes = split(a:side, ',')
  call sj#TrimList(nodes)
  call uniq(sort(nodes))
  return nodes
endfunction

function! sj#dot#ExtractEdges(statement)
  let sides = split(a:statement, s:edge) 
  if len(sides) < 2 | return [] | endif
  let [edges, idx] = [[], 0]
  while idx < len(sides) - 1
    " handling of chained expressions
    " such as A -> B -> C
    let edges += [[sj#dot#ExtractNodes(get(sides, idx)),
          \ sj#dot#ExtractNodes(get(sides, idx + 1))]]
    let idx = idx + 1
  endwhile
  return edges
endfunction
" }}}

" Callback functions {{{

function! sj#dot#SplitStatement()
  let statements = split(getline('.'), ';')
  if len(statements) < 2 | return 0 | endif
  call map(statements, 'v:val . ";"')
  call sj#ReplaceMotion('V', join(statements, "\n"))
  return 1
endfunction

function! sj#dot#JoinStatement()
  " unused
  join
endfunction

function! sj#dot#SplitEdge()
  let line = getline('.')
  " chop off potential trailing ;
  let statement = split(line, ';')[-1]
  " Split to elements of an edge
  " let sides = split(statement, s:edge) 
  " if len(sides) < 2
  "   return 0
  " endif

  " let [edges, idx] = [[], 0]
  " while idx < len(sides) - 1
  "   " handling of chained expressions
  "   " such as A -> B -> C
  "   let edges += [[sj#dot#ExtractNodes(get(sides, idx)),
  "         \ sj#dot#ExtractNodes(get(sides, idx + 1))]]
  "   let idx = idx + 1
  " endwhile
  let edges = sj#dot#ExtractEdges(statement)

  if !len(edges) | return 0 | endif

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

function! s:MergeEdges(edges)
  let edges = copy(a:edges)
  let finished = 0
  for [src_nodes, dst_nodes] in edges
    call uniq(sort(src_nodes))
    call uniq(sort(dst_nodes))
  endfor
  " all node sets sorted
  call uniq(sort(edges))
  " all edges sorted
  while !finished
    let finished = 1
    let idx = 0
    while idx < len(edges)
      let [source_nodes, dest_nodes] = edges[idx]
      let jdx = idx + 1
      while jdx < len(edges)
        if source_nodes == edges[jdx][0]
          let dest_nodes += edges[jdx][1]
          call uniq(sort(dest_nodes))
          let finished = 0
        elseif dest_nodes == edges[jdx][1]
          let source_nodes += edges[jdx][0]
          call uniq(sort(source_nodes))
          let finished = 0
        endif
        if !finished
          unlet edges[jdx]
        else
          let jdx += 1
        endif
      endwhile
      let idx = idx + 1
    endwhile
    call uniq(sort(edges))
  endwhile
  return edges
endfunction

function! s:ChainTransitiveEdges(edges)
  let edges = copy(a:edges)
  let finished = 0
  while !finished
    let finished = 1
    let idx = 0
    while idx < len(edges)
      let jdx = idx + 1
      while jdx < len(edges)
        if edges[idx][-1] == edges[jdx][0]
          " FIXME
          let edges[idx] = edges[idx][0] + edges[jdx][-1]
          let finished = 0
        endif
        if !finished
          unlet edges[jdx]
        else
          let jdx += 1
        endif
      endwhile
      let idx += 1
    endwhile
  endwhile
endfunction

function! s:Edge2string(edge)
  " FIXME
  let edge = copy(a:edge)
  let edge = map(edge, 'join(v:val, ", ")'})
  let edge = join(edge, ' -> ')
  let edge = edge . ';'
  return edge
endfunction

function! sj#dot#JoinEdge()
  call sj#PushCursor()
  let s1 = substitute(getline('.'), ';$', '', '')
  normal! j
  let s2 = substitute(getline('.'), ';$', '', '')
  call sj#PopCursor()
  let edges1 = sj#dot#ExtractEdges(s1)
  let edges2 = sj#dot#ExtractEdges(s2)
  let edges = edges1 + edges2
  let edges = s:MergeEdges(edges)
  echo edges
  let edges = s:ChainTransitiveEdges(edges)
  if len(edges) > 1 | return 0 | endif
  call sj#ReplaceMotion('Vj', s:Edge2string(edges[0]))
  return 1
endfunction
" }}}
