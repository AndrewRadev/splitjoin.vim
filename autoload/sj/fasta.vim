function! sj#fasta#SplitSequence() abort
  " Check we're on a header line:
  if getline('.') !~ '^>'
    return 0
  endif
  let header_lineno = line('.')

  " Check that the next line is a sequence
  if getline(header_lineno + 1) =~ '^>'
    return 0
  endif
  let sequence_lineno = header_lineno + 1
  let sequence_line = getline(sequence_lineno)

  " Check that the next next line is a header
  if getline(header_lineno + 2) !~ '^>'
    return 0
  endif

  let width = sj#settings#Read('fasta_textwidth')
  if width <= 0
    let width = &textwidth
  endif
  if width <= 0
    let width = 80
  endif

  let split_sequence_line = substitute(sequence_line, '.\{'..width..'}', '\0\n', 'g')
  call sj#ReplaceLines(sequence_lineno, sequence_lineno, split_sequence_line)
  return 1
endfunction

function! sj#fasta#JoinSequence() abort
  " Check we're on a header line:
  if getline('.') !~ '^>'
    return 0
  endif
  let header_lineno = line('.')
  let start_lineno = header_lineno + 1

  " Find next header line, if any:
  let next_header_lineno = search('^>', 'W')
  if next_header_lineno > 0
    let end_lineno = next_header_lineno - 1
  else
    let end_lineno = line('$')
  endif

  if end_lineno - start_lineno <= 0
    " No sequence lines to join
    return 0
  endif

  call sj#Keeppatterns(start_lineno..','..(end_lineno - 1)..'s/\n//g')
  return 1
endfunction
