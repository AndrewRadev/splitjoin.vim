" Constructor:
" ============

function! sj#rubyparse#Parser(start_index, end_index, line)
  let parser = sj#argparser#Construct(a:start_index, a:end_index, a:line)

  call extend(parser, {
        \ 'Process':          function('sj#rubyparse#Process'),
        \ 'PushArg':          function('sj#rubyparse#PushArg'),
        \ 'AtFunctionEnd':    function('sj#rubyparse#AtFunctionEnd'),
        \ 'ExpandOptionHash': function('sj#rubyparse#ExpandOptionHash'),
        \ })

  return parser
endfunction

" Methods:
" ========

function! sj#rubyparse#Process() dict
  while !self.Finished()
    if self.body[0] == ','
      call self.PushArg()
      call self.Next()
      continue
    elseif self.AtFunctionEnd()
      break
    elseif self.body[0] =~ "[\"'{\[`(/]"
      call self.JumpPair("\"'{[`(/", "\"'}]`)/")
    elseif self.body[0] == '%'
      call self.PushChar()
      if self.body[0] =~ '[qQrswWx]'
        call self.PushChar()
      endif
      let delimiter = self.body[0]
      call self.JumpPair(delimiter, delimiter)
    elseif self.body =~ '^=>'
      let self.current_arg_type = 'option'
      call self.PushChar()
    endif

    call self.PushChar()
  endwhile

  if len(self.current_arg) > 0
    call self.PushArg()
  endif
  call self.ExpandOptionHash()

  let self.args = map(self.args, 'sj#Trim(v:val)')
  let self.opts = map(self.opts, 'sj#Trim(v:val)')
endfunction

" Pushes the current argument either to the args or opts stack and initializes
" a new one.
function! sj#rubyparse#PushArg() dict
  if self.current_arg_type == 'option'
    call add(self.opts, self.current_arg)
  else
    call add(self.args, self.current_arg)
  endif

  let self.current_arg      = ''
  let self.current_arg_type = 'normal'
endfunction


" If the last argument is a hash and no options have been parsed, splits the
" last argument and fills the options with it.
function! sj#rubyparse#ExpandOptionHash() dict
  if len(self.opts) <= 0 && len(self.args) > 0
    " then try parsing the last parameter
    let last = sj#Trim(self.args[-1])
    if last =~ '^{.*=>.*}$'
      " then it seems to be a hash, expand it
      call remove(self.args, -1)

      let hash = sj#ExtractRx(last, '^{\(.*=>.*\)}$', '\1')

      let [_from, _to, _args, opts] = sj#rubyparse#ParseArguments(0, -1, hash)
      call extend(self.opts, opts)
    endif
  endif
endfunction

" Returns true if the parser is at the function's end, either because of a
" closing brace, a "do" clause or a "%>".
function! sj#rubyparse#AtFunctionEnd() dict
  if self.body[0] == ')'
    return 1
  elseif self.body =~ '\v^\s*do(\s*\|.*\|)?(\s*-?\%\>\s*)?$'
    return 1
  elseif self.body =~ '^\s*-\?%>'
    return 1
  endif

  return 0
endfunction

" Public functions:
" =================

function! sj#rubyparse#LocateFunction()
  let [_bufnum, line, col, _off] = getpos('.')

  " The pattern consists of the following:
  "
  "   - a keyword
  "   - spaces or an opening round bracket
  "   - something that's not a comma and doesn't look like an operator
  "     (to avoid a few edge cases)
  "
  let pattern = '\v(^|\s|\.|::)\k+[?!]?(\s+|\s*\(\s*)[^,=<>+-/*^%]'
  let found = search(pattern, 'bcWe', line('.'))
  if found <= 0
    " try searching forward
    let found = search(pattern, 'cWe', line('.'))
  endif
  if found > 0
    let from = col('.') - 1
    let to   = -1 " we're not sure about the end right now

    return [from, to]
  endif

  return [-1, -1]
endfunction

function! sj#rubyparse#LocateHash()
  let [_bufnum, line, col, _off] = getpos('.')

  let found = searchpair('{', '', '}', 'cb', '', line('.'))
  if found > 0
    let from = col('.') - 1
    normal! %
    let to = col('.')

    return [from, to]
  else
    return [-1, -1]
  endif
endfunction

function! sj#rubyparse#ParseArguments(start_index, end_index, line)
  let parser = sj#rubyparse#Parser(a:start_index, a:end_index, a:line)
  call parser.Process()
  return [ a:start_index + 1, parser.index, parser.args, parser.opts ]
endfunction
