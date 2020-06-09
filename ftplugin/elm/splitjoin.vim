if !exists('b:splitjoin_split_callbacks')
  let b:splitjoin_split_callbacks = [
        \ 'sj#elm#SplitList',
        \ 'sj#elm#SplitTuple',
        \ ]
endif
