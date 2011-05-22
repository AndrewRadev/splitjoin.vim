function! sj#rubyparse#LocateFunctionStart()
  let [_bufnum, line, col, _off] = getpos('.')

  " first case, brackets: foo(bar, baz)
  " TODO strings, comments
  let found = searchpair('(', '', ')', 'cb', '', line('.'))
  if found > 0
    return col('.')
  endif

  " second case, bracketless: foo bar, baz
  " starts with a keyword, then spaces, then something that's not a comma
  let found = search('\v(^|\s)\k+\s+[^,]', 'bcWe', line('.'))
  if found > 0
    return col('.') - 1
  endif

  return -1
endfunction

function! sj#rubyparse#ParseArguments(function_start)
  let body = getline('.')
  let body = strpart(body, a:function_start)

  let index            = a:function_start
  let args             = []
  let opts             = []
  let current_arg      = ''
  let current_arg_type = 'normal'

  while strlen(body) > 0
    if body[0] == ','
      if current_arg_type == 'option'
        call add(opts, current_arg)
      else
        call add(args, current_arg)
      endif

      let current_arg_type = 'normal'
      let current_arg      = ''
    elseif body[0] == ')'
      break
    elseif body =~ '^=>'
      let current_arg_type = 'option'
      let current_arg .= body[0]
    else
      let current_arg .= body[0]
    endif

    let body  = strpart(body, 1)
    let index = index + 1
  endwhile

  if current_arg_type == 'option'
    call add(opts, current_arg)
  else
    call add(args, current_arg)
  endif

  return [ a:function_start + 1, index, args, opts ]
endfunction
