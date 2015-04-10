let b:splitjoin_split_callbacks = [
      \ 'sj#js#SplitArray',
      \ 'sj#php#SplitBraces',
      \ 'sj#php#SplitIfClause',
      \ 'sj#html#SplitTags',
      \ 'sj#php#SplitPhpMarker',
      \ ]

let b:splitjoin_join_callbacks = [
      \ 'sj#php#JoinPhpMarker',
      \ 'sj#js#JoinArray',
      \ 'sj#php#JoinBraces',
      \ 'sj#php#JoinIfClause',
      \ 'sj#php#JoinHtmlTags',
      \ ]
