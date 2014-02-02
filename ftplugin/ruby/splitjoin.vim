if !exists('b:splitjoin_split_callbacks')
  let b:splitjoin_split_callbacks = [
        \ 'sj#ruby#SplitIfClause',
        \ 'sj#ruby#SplitTernaryClause',
        \ 'sj#ruby#SplitOptions',
        \ 'sj#ruby#SplitBlock',
        \ 'sj#ruby#SplitCachingConstruct',
        \ 'sj#ruby#SplitString',
        \ 'sj#ruby#SplitWhenThen',
        \ 'sj#ruby#SplitCase',
        \ ]
endif

if !exists('b:splitjoin_join_callbacks')
  let b:splitjoin_join_callbacks = [
        \ 'sj#ruby#JoinBlock',
        \ 'sj#ruby#JoinHash',
        \ 'sj#ruby#JoinIfClause',
        \ 'sj#ruby#JoinTernaryClause',
        \ 'sj#ruby#JoinCachingConstruct',
        \ 'sj#ruby#JoinContinuedMethodCall',
        \ 'sj#ruby#JoinHeredoc',
        \ 'sj#ruby#JoinWhenThen',
        \ 'sj#ruby#JoinCase',
        \ ]
endif
