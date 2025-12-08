if !exists('b:splitjoin_split_callbacks')
  let b:splitjoin_split_callbacks = [
        \ 'sj#python#SplitString',
        \ 'sj#python#SplitListComprehension',
        \ 'sj#python#SplitArgs',
        \ 'sj#python#SplitBracketedItem',
        \ 'sj#python#SplitAssignment',
        \ 'sj#python#SplitTernaryAssignment',
        \ 'sj#python#SplitStatement',
        \ 'sj#python#SplitImport',
        \ ]
endif

if !exists('b:splitjoin_join_callbacks')
  let b:splitjoin_join_callbacks = [
        \ 'sj#python#JoinImportWithNewlineEscape',
        \ 'sj#python#JoinImportWithRoundBrackets',
        \ 'sj#python#JoinMultilineString',
        \ 'sj#python#JoinBracketsAtEOL',
        \ 'sj#python#JoinTuple',
        \ 'sj#python#JoinArgs',
        \ 'sj#python#JoinArray',
        \ 'sj#python#JoinTernaryAssignment',
        \ 'sj#python#JoinStatement',
        \ 'sj#python#JoinAssignment',
        \ ]
endif
