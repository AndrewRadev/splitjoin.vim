if !exists('b:splitjoin_split_callbacks')
    let b:splitjoin_split_callbacks = [
        \ 'sj#c#SplitFuncall',
        \ 'sj#c#SplitIfClause'
        \ ]
endif

if !exists('b:splitjoin_join_callbacks')
  let b:splitjoin_join_callbacks = [
        \ 'sj#c#JoinFuncall',
        \ 'sj#c#JoinIfClause'
        \ ]
endif
