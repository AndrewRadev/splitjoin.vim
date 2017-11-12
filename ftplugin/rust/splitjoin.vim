let b:splitjoin_split_callbacks = [
      \ 'sj#rust#SplitMatchClause',
      \ 'sj#rust#SplitQuestionMark',
      \ 'sj#js#SplitObjectLiteral',
      \ ]

let b:splitjoin_join_callbacks = [
      \ 'sj#rust#JoinMatchClause',
      \ 'sj#rust#JoinQuestionMark',
      \ 'sj#js#JoinObjectLiteral',
      \ ]
