let b:splitjoin_split_callbacks = [
      \ 'sj#rust#SplitMatchClause',
      \ 'sj#rust#SplitQuestionMark',
      \ 'sj#rust#SplitClosure',
      \ 'sj#js#SplitObjectLiteral',
      \ 'sj#rust#SplitExprIntoEmptyMatch',
      \ ]

let b:splitjoin_join_callbacks = [
      \ 'sj#rust#JoinMatchClause',
      \ 'sj#rust#JoinQuestionMark',
      \ 'sj#rust#JoinClosure',
      \ 'sj#js#JoinObjectLiteral',
      \ ]
