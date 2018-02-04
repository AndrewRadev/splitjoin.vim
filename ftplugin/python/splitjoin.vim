if !exists('b:splitjoin_split_callbacks')
  let b:splitjoin_split_callbacks = [
        \ 'sj#python#SplitTuple',
        \ 'sj#python#SplitAssignment',
        \ 'sj#python#SplitDict',
        \ 'sj#python#SplitArray',
        \ 'sj#python#SplitStatement',
        \ 'sj#python#SplitImport',
        \ ]
endif

if !exists('b:splitjoin_join_callbacks')
  let b:splitjoin_join_callbacks = [
        \ 'sj#python#JoinTuple',
        \ 'sj#python#JoinDict',
        \ 'sj#python#JoinArray',
        \ 'sj#python#JoinStatement',
        \ 'sj#python#JoinImport',
        \ 'sj#python#JoinAssignment',
        \ ]
endif
