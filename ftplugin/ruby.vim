" Wrap them in conditions to avoid messing up erb

if !exists('b:splitjoin_split_callbacks')
  let b:splitjoin_split_callbacks = [
        \ 'sj#ruby#SplitIfClause',
        \ 'sj#ruby#SplitBlock',
        \ ]
endif

if !exists('b:splitjoin_join_callbacks')
  let b:splitjoin_join_callbacks = [
        \ 'sj#ruby#JoinIfClause',
        \ 'sj#ruby#JoinBlock',
        \ ]
endif
