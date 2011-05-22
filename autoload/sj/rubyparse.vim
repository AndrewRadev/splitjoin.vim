" Data structure:
" ===============
function! ParseData(function_start)
  return {
        \ 'args':             [],
        \ 'opts':             [],
        \ 'index':            a:function_start,
        \ 'current_arg':      '',
        \ 'current_arg_type': 'normal',
        \ }
endfunction


" Public functions:
" =================

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
  let parse_data = ParseData(a:function_start)

  let parse_data.body = getline('.')
  let parse_data.body = strpart(parse_data.body, a:function_start)

  while strlen(parse_data.body) > 0
    if parse_data.body[0] == ','
      if parse_data.current_arg_type == 'option'
        call add(parse_data.opts, parse_data.current_arg)
      else
        call add(parse_data.args, parse_data.current_arg)
      endif

      let parse_data.current_arg_type = 'normal'
      let parse_data.current_arg      = ''
    elseif parse_data.body[0] == ')'
      break
    elseif parse_data.body =~ '^=>'
      let parse_data.current_arg_type = 'option'
      let parse_data.current_arg .= parse_data.body[0]
    else
      let parse_data.current_arg .= parse_data.body[0]
    endif

    let parse_data.body  = strpart(parse_data.body, 1)
    let parse_data.index = parse_data.index + 1
  endwhile

  if parse_data.current_arg_type == 'option'
    call add(parse_data.opts, parse_data.current_arg)
  else
    call add(parse_data.args, parse_data.current_arg)
  endif

  return [ a:function_start + 1, parse_data.index, parse_data.args, parse_data.opts ]
endfunction
