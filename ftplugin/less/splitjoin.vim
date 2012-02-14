" just use the CSS ones

if !exists('b:splitjoin_split_callbacks')
  let b:splitjoin_split_callbacks = [
        \ 'sj#css#SplitDefinition',
        \ ]
endif

if !exists('b:splitjoin_join_callbacks')
  let b:splitjoin_join_callbacks = [
        \ 'sj#css#JoinDefinition',
        \ 'sj#css#JoinMultilineSelector',
        \ ]
endif
