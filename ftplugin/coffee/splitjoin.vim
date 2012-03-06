if !exists('b:splitjoin_split_callbacks')
  let b:splitjoin_split_callbacks = [
        \ 'sj#coffee#SplitFunction',
        \ 'sj#coffee#SplitIfClause',
        \ 'sj#coffee#SplitObjectLiteral'
        \ ]
endif

if !exists('b:splitjoin_join_callbacks')
  let b:splitjoin_join_callbacks = [
        \ 'sj#coffee#JoinFunction',
        \ 'sj#coffee#JoinIfClause',
        \ 'sj#coffee#JoinObjectLiteral'
        \ ]
endif
