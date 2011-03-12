let b:splitjoin_split_callbacks = [
      \ 'sj#html#SplitTags',
      \ 'sj#eruby#SplitIfClause',
      \ ]

let b:splitjoin_join_callbacks = [
      \ 'sj#eruby#JoinIfClause',
      \ 'sj#html#JoinTags',
      \ ]
