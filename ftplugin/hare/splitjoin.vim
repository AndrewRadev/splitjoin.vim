let b:splitjoin_trailing_comma = 1

let b:splitjoin_split_callbacks = [
      \ 'sj#hare#SplitQuestionMark',
      \ 'sj#rust#SplitCurlyBrackets',
      \ 'sj#rust#SplitArray',
      \ 'sj#rust#SplitArgs',
      \ ]

let b:splitjoin_join_callbacks = [
      \ 'sj#rust#JoinCurlyBrackets',
      \ 'sj#rust#JoinArray',
      \ 'sj#rust#JoinArgs',
      \ ]
