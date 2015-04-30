if !exists('b:splitjoin_split_callbacks')
  let b:splitjoin_split_callbacks = [
        \ 'sj#ruby#SplitArrayLiteral',
        \ 'sj#ruby#SplitProcShorthand',
        \ 'sj#ruby#SplitBlock',
        \ 'sj#ruby#SplitIfClause',
        \ 'sj#ruby#SplitOptions',
        \ 'sj#ruby#SplitCachingConstruct',
        \ 'sj#ruby#SplitString',
        \ 'sj#ruby#SplitWhenThen',
        \ 'sj#ruby#SplitCase',
        \ 'sj#ruby#SplitTernaryClause',
        \ ]
endif

if !exists('b:splitjoin_join_callbacks')
  let b:splitjoin_join_callbacks = [
        \ 'sj#ruby#JoinArrayLiteral',
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
