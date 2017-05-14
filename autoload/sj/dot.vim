let s:skip = sj#SkipSyntax(['dotString','dotComment'])
let s:edge = '->'


" Callback functions {{{
function! sj#dot#SplitStatement()
  if sj#SearchSkip(';\s*\S', s:skip, '', line('.'))
    execute "normal! a\<CR>"
    return 1
  else
    return 0
  endif
endfunction

function! sj#dot#JoinStatement()
  " TODO guard for comments etc
  normal! J
  return 1
endfunction

function! sj#dot#SplitChainedEdge()
  " FIXME Now sj#dot#SplitStatement does not assert only single line statements afterwards,
  " so there might occur an error here.  let line = getline('.')
  let l:line = getline('.')
  if l:line !~ s:edge . '.*' . s:edge | return 0 | endif
  let l:statement = s:TrimSemicolon(l:line)
  let l:edges = s:ExtractEdges(l:statement)
  call map(l:edges, 's:Edge2string(v:val)')
  call sj#ReplaceMotion('V', join(l:edges, "\n"))
  return 1
endfunction

function! sj#dot#JoinChainedEdge()
  " TODO initial guard 
  let [edges, ate] = s:ParseConsecutiveLines()
  let edges = s:ChainTransitiveEdges(edges)
  " should not be more than one, but also not zero
  if len(edges) != 1 | return 0 | endif
  let edge_string = s:Edge2string(edges[0])
  call sj#ReplaceMotion(ate ? 'Vj' : 'V', edge_string) 
  return 1
endfunction

function! sj#dot#SplitMultiEdge()
  " chop off potential trailing ';'
  let statement = substitute(getline('.'), ';$', '', '') 
  let edges = s:ExtractEdges(statement)
  if !len(edges) | return 0 | endif
  " Note that this is something else than applying map -> Edge2string
  " since we need to expand all-to-all property of multi-edges
  let new_edges = []
  for edge in edges
    let [lhs, rhs] = edge
    for source_node in lhs
      for dest_node in rhs
        let new_edges += [s:Edge2string([[source_node], [dest_node]])]
      endfor
    endfor
  endfor
  let body = join(new_edges, "\n")
  call sj#ReplaceMotion('V', body)
  return 1
endfunction

function! sj#dot#JoinMultiEdge()
  " TODO guard for comments or blank lines
  " Check whether two lines are 
  let [edges, ate] = s:ParseConsecutiveLines()
  if len(edges) < 2 | return 0 | endif
  let edges = s:MergeEdges(edges)
  if len(edges) != 1 | return 0 | endif
  call sj#ReplaceMotion(ate ? 'Vj' : 'V', s:Edge2string(edges[0]))
  return 1
endfunction
" }}}

" Helper functions {{{
" Split multiple nodes into single elements
" INPUT: 'A, B, C'
" OUTPUT: ['A', 'B', 'C']
function! s:ExtractNodes(side)
  " FIXME will fail on 'A, B, "some,label"'
  let l:nodes = split(a:side, ',')
  call sj#TrimList(l:nodes)
  call uniq(sort(l:nodes))
  echo l:nodes
  return l:nodes
endfunction

function! s:TrimSemicolon(statement)
  return substitute(a:statement, ';$', '', '') 
endfunction

" Extract elements of potentially chained edges as [src,dst] pairs
" INPUT: 'A, B -> C -> D'
" OUTPUT: List of edges [[[A, B], [C]], [[C], [D]]]
function! s:ExtractEdges(statement)
  let l:statement = s:TrimSemicolon(a:statement)
  " FIXME will fail if '->' inside "s
  let l:sides = split(l:statement, s:edge) 
  if len(l:sides) < 2 | return [] | endif
  let [l:edges, l:idx] = [[], 0]
  while l:idx < len(l:sides) - 1
    " handling of chained expressions
    " such as A -> B -> C
    let l:edges += [[s:ExtractNodes(get(l:sides, l:idx)),
          \ s:ExtractNodes(get(l:sides, l:idx + 1))]]
    let l:idx = l:idx + 1
  endwhile
  return l:edges
endfunction

" OUTPUT: Either [edges, 0] when 2 statements on first line, else [edges, 1]
" when two statements on two lines
function! s:ParseConsecutiveLines(...)
  " Safety guard, because multiple statements are not handled at the moment
  let l:statements = split(getline('.'), ';')
  if len(l:statements) > 2
    return [[], 0]
  elseif len(l:statements) == 2
    " only if exactly 2 edges in one line, else replacemotion fails (atm)
    let l:edges = s:ExtractEdges(l:statements[0]) +
          \ s:ExtractEdges(l:statements[1])
    return [l:edges, 0]
  elseif len(l:statements) == 0
    return [[], 0]
  endif
  " Exactly one statement found on the first lien
  " Try to eat the next line

  call sj#PushCursor()
  if line('.') + 1 == line('$') | return [[], 0] | endif
  normal! j
  let l:statements2 = split(getline('.'), ';')
  if len(l:statements2) > 1
    return [[], 1]
  endif
  let l:edges = s:ExtractEdges(l:statements[0]) + 
        \ s:ExtractEdges(l:statements2[0])
  call sj#PopCursor()
  return [l:edges, 1]
endfunction

" INPUT: [[src_nodes], [dst_nodes]]
" OUTPUT: string representation of the aequivalent statement
function! s:Edge2string(edge)
  let l:edge = copy(a:edge)
  let l:edge = map(l:edge, 'join(v:val, ", ")')
  let l:edge = join(l:edge, ' -> ')
  let l:edge = l:edge . ';'
  return l:edge
endfunction

" INPUT: Set of potentially mergable edges
" OUTPUT: Set of edges containing multi-edges
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

" INPUT: set of potentially transitive edges
" OUTPUT: all transitive edges are merged into chained edges
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
          let edges[idx] += [edges[jdx][-1]]
          let finished = 0
          unlet edges[jdx]
          break
        endif
        let jdx += 1
      endwhile
      let idx += 1
    endwhile
  endwhile
  return edges
endfunction

" }}}
