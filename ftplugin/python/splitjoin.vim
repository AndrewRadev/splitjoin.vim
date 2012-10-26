if !exists('b:splitjoin_split_callbacks')
  let b:splitjoin_split_callbacks = [
        \ 'sj#python#SplitDict',
        \ 'sj#python#SplitArray',
        \ 'sj#python#SplitTuple',
        \ 'sj#python#SplitStatement',
        \ 'sj#python#SplitImport'
        \ ]
endif

if !exists('b:splitjoin_join_callbacks')
  let b:splitjoin_join_callbacks = [
        \ 'sj#python#JoinDict',
        \ 'sj#python#JoinArray',
        \ 'sj#python#JoinTuple',
        \ 'sj#python#JoinStatement',
        \ 'sj#python#JoinImport'
        \ ]
endif
