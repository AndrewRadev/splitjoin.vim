if !exists('b:splitjoin_split_callbacks')
  let b:splitjoin_split_callbacks = [
        \ 'sj#coffee#SplitFunction',
        \ 'sj#coffee#SplitIfClause',
        \ ]
endif

if !exists('b:splitjoin_join_callbacks')
  let b:splitjoin_join_callbacks = [
        \ 'sj#coffee#JoinFunction',
        \ 'sj#coffee#JoinIfClause',
        \ ]
endif
