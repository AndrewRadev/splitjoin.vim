if !exists('b:splitjoin_split_callbacks')
  let b:splitjoin_split_callbacks = [
        \ 'sj#php#SplitArray',
        \ 'sj#html#SplitTags',
        \ ]
endif

if !exists('b:splitjoin_join_callbacks')
  let b:splitjoin_join_callbacks = [
        \ 'sj#php#JoinArray',
        \ 'sj#html#JoinTags',
        \ ]
endif
