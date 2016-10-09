let b:splitjoin_split_callbacks = [
      \ 'sj#html#SplitTags',
      \ 'sj#html#SplitAttributes',
      \ 'sj#js#SplitArray',
      \ 'sj#js#SplitObjectLiteral',
      \ 'sj#js#SplitFunction',
      \ 'sj#js#SplitOneLineIf',
      \ 'sj#js#SplitArgs'
      \ ]

let b:splitjoin_join_callbacks = [
      \ 'sj#html#JoinAttributes',
      \ 'sj#html#JoinTags',
      \ 'sj#js#JoinArray',
      \ 'sj#js#JoinArgs',
      \ 'sj#js#JoinFunction',
      \ 'sj#js#JoinOneLineIf',
      \ 'sj#js#JoinObjectLiteral',
      \ ]
