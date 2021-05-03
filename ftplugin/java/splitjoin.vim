if !exists('b:splitjoin_split_callbacks')
  let b:splitjoin_split_callbacks = [
        \ 'sj#java#SplitIfClause',
        \ 'sj#java#SplitFuncall',
        \ ]
endif

if !exists('b:splitjoin_join_callbacks')
  let b:splitjoin_join_callbacks = [
        \ 'sj#java#JoinFuncall',
        \ 'sj#java#JoinIfClause',
        \ ]
endif
