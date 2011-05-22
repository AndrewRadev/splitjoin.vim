" Data structure:
" ===============

function! s:InitParseData(function_start) dict
  let self.args             = []
  let self.opts             = []
  let self.index            = a:function_start
  let self.current_arg      = ''
  let self.current_arg_type = 'normal'

  let self.body = getline('.')
  let self.body = strpart(self.body, a:function_start)
endfunction

function! s:PushArg() dict
  if self.current_arg_type == 'option'
    call add(self.opts, self.current_arg)
  else
    call add(self.args, self.current_arg)
  endif

  let self.current_arg      = ''
  let self.current_arg_type = 'normal'
endfunction

function! s:PushChar() dict
  let self.current_arg .= self.body[0]
  call self.next()
endfunction

function! s:Next() dict
  let self.body  = strpart(self.body, 1)
  let self.index = self.index + 1
endfunction

function! s:Finished() dict
  return len(self.body) <= 0
endfunction

let s:parser = {
      \ 'args':             [],
      \ 'opts':             [],
      \ 'index':            0,
      \ 'current_arg':      '',
      \ 'current_arg_type': 'normal',
      \
      \ 'init':      function("s:InitParseData"),
      \ 'push_arg':  function("s:PushArg"),
      \ 'push_char': function("s:PushChar"),
      \ 'next':      function("s:Next"),
      \ 'finished':  function("s:Finished"),
      \ }

" Constructor:
" ============

function! s:Parser(function_start)
  let parser = s:parser
  call parser.init(a:function_start)
  return parser
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
  let parser = s:Parser(a:function_start)

  while !parser.finished()
    if parser.body[0] == ','
      call parser.push_arg()
      call parser.next()
      continue
    elseif parser.body[0] == ')'
      break
    elseif parser.body =~ '^=>'
      let parser.current_arg_type = 'option'
      call parser.push_char()
    endif

    call parser.push_char()
  endwhile

  call parser.push_arg()

  return [ a:function_start + 1, parser.index, parser.args, parser.opts ]
endfunction
