let b:splitjoin_split_callbacks = [
      \ 'sj#rust#SplitBlockClosure',
      \ 'sj#rust#SplitExprClosure',
      \ 'sj#rust#SplitMatchClause',
      \ 'sj#rust#SplitQuestionMark',
      \ 'sj#rust#SplitCurlyBrackets',
      \ 'sj#rust#SplitUnwrapIntoEmptyMatch',
      \ ]

let b:splitjoin_join_callbacks = [
      \ 'sj#rust#JoinMatchClause',
      \ 'sj#rust#JoinMatchStatement',
      \ 'sj#rust#JoinClosure',
      \ 'sj#rust#JoinCurlyBrackets',
      \ ]
