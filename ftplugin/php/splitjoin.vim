let b:splitjoin_split_callbacks = [
      \ 'sj#js#SplitArray',
      \ 'sj#php#SplitArray',
      \ 'sj#php#SplitIfClause',
      \ 'sj#html#SplitTags',
      \ ]

let b:splitjoin_join_callbacks = [
      \ 'sj#js#JoinArray',
      \ 'sj#php#JoinArray',
      \ 'sj#php#JoinIfClause',
      \ 'sj#php#JoinHtmlTags',
      \ ]
