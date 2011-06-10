function! sj#css#SplitDefinition()
  if !s:LocateDefinition()
    return 0
  endif

  let body = sj#GetMotion('Vi{')

  let lines = split(body, ";\s*")
  let lines = map(lines, 'sj#Trim(v:val)')
  let lines = filter(lines, 'v:val !~ "^\s*$"')

  let body = join(lines, ";\n") . ";"

  call sj#ReplaceMotion('Va{', "{\n".body."\n}")

  return 1
endfunction

function! sj#css#JoinDefinition()
  if !s:LocateDefinition()
    return 0
  endif

  if getline('.') =~ '{.*}' " then there's nothing to join
    return 0
  endif

  let body = sj#GetMotion('Vi{')

  let lines = split(body, ";\s*\n")
  let lines = map(lines, 'sj#Trim(v:val)')
  let lines = filter(lines, 'v:val !~ "^\s*$"')

  let body = join(lines, "; ")
  let body = substitute(body, ';\?$', ';', '')

  call sj#ReplaceMotion('Va{', '{ '.body.' }')

  return 1
endfunction

function! s:LocateDefinition()
  if search('{', 'bcW', line('.')) <= 0 && search('{', 'cW', line('.')) <= 0
    return 0
  else
    return 1
  endif
endfunction
