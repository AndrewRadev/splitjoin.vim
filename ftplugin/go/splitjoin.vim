let b:splitjoin_split_callbacks = [
      \ 'sj#go#SplitImports',
      \ 'sj#go#SplitStruct',
      \ ]

let b:splitjoin_join_callbacks = [
      \ 'sj#go#JoinImports',
      \ 'sj#go#JoinStruct',
      \ ]
