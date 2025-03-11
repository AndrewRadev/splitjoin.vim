if !exists('b:splitjoin_split_callbacks')
  let b:splitjoin_split_callbacks = [
        \ 'sj#dot#SplitStatement',
        \ 'sj#dot#SplitChainedEdge',
        \ 'sj#dot#SplitMultiEdge'
        \ ]
endif

if !exists('b:splitjoin_join_callbacks')
  let b:splitjoin_join_callbacks = [
        \ 'sj#dot#JoinMultiEdge',
        \ 'sj#dot#JoinChainedEdge',
        \ 'sj#dot#JoinStatement'
        \ ]
endif
