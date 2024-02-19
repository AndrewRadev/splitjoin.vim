if !exists('b:splitjoin_split_callbacks')
      let b:splitjoin_split_callbacks = [
            \ 'sj#cue#SplitStructLiteral',
            \ 'sj#cue#SplitArray',
            \ 'sj#cue#SplitArgs',
            \ ]
endif

if !exists('b:splitjoin_join_callbacks')
      let b:splitjoin_join_callbacks = [
            \ 'sj#cue#JoinStructLiteral',
            \ 'sj#cue#JoinArray',
            \ 'sj#cue#JoinArgs',
            \ ]
endif

" in CUE, trailing comma means something else
let b:splitjoin_trailing_comma = 0
