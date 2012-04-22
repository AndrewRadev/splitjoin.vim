if !exists('b:splitjoin_split_callbacks')
  let b:splitjoin_split_callbacks = [
        \ 'sj#perl#SplitIfClause',
        \ 'sj#perl#SplitAndClause',
        \ 'sj#perl#SplitOrClause',
        \ ]
endif

if !exists('b:splitjoin_join_callbacks')
  let b:splitjoin_join_callbacks = [
        \ 'sj#perl#JoinIfClause',
        \ ]
endif
