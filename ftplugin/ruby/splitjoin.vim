if !exists('b:splitjoin_split_callbacks')
  let b:splitjoin_split_callbacks = [
        \ 'sj#ruby#SplitIfClause',
        \ 'sj#ruby#SplitOptions',
        \ 'sj#ruby#SplitBlock',
        \ 'sj#ruby#SplitCachingConstruct',
        \ ]
endif

if !exists('b:splitjoin_join_callbacks')
  let b:splitjoin_join_callbacks = [
        \ 'sj#ruby#JoinBlock',
        \ 'sj#ruby#JoinHash',
        \ 'sj#ruby#JoinIfClause',
        \ 'sj#ruby#JoinCachingConstruct',
        \ ]
endif
