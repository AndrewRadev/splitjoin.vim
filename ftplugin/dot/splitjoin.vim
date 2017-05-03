if !exists('b:splitjoin_split_callbacks')
  let b:splitjoin_split_callbacks = [
        \ 'sj#dot#SplitStatement',
        \ 'sj#dot#SplitEdge'
        \ ]
endif

if !exists('b:splitjoin_join_callbacks')
  let b:splitjoin_join_callbacks = [
        \ 'sj#dot#JoinEdge',
        \ 'sj#dot#JoinStatement'
        \ ]
endif
