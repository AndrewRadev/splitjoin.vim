if !exists('b:splitjoin_split_callbacks')
  let b:splitjoin_split_callbacks = [
        \ 'sj#js#SplitArray',
        \ 'sj#php#SplitArray',
        \ 'sj#html#SplitTags',
        \ ]
endif

if !exists('b:splitjoin_join_callbacks')
  let b:splitjoin_join_callbacks = [
        \ 'sj#js#JoinArray',
        \ 'sj#php#JoinArray',
        \ 'sj#php#JoinHtmlTags',
        \ ]
endif
