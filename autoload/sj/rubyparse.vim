" Constructor:
" ============

function! s:Parser(start_index, end_index, line)
  let parser = {
        \ 'args':             [],
        \ 'opts':             [],
        \ 'body':             a:line,
        \ 'index':            a:start_index,
        \ 'current_arg':      '',
        \ 'current_arg_type': 'normal',
        \
        \ 'Process':          function('s:Process'),
        \ 'PushArg':          function('s:PushArg'),
        \ 'PushChar':         function('s:PushChar'),
        \ 'Next':             function('s:Next'),
        \ 'JumpPair':         function('s:JumpPair'),
        \ 'AtFunctionEnd':    function('s:AtFunctionEnd'),
        \ 'Finished':         function('s:Finished'),
        \ 'ExpandOptionHash': function('s:ExpandOptionHash'),
        \ }

  if a:start_index > 0
    let parser.body = strpart(parser.body, a:start_index)
  endif
  if a:end_index > 0
    let parser.body = strpart(parser.body, 0, a:end_index - a:start_index)
  endif

  return parser
endfunction

" Methods:
" ========

function! s:Process() dict
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
function! s:PushArg() dict
  if self.current_arg_type == 'option'
    call add(self.opts, self.current_arg)
  else
    call add(self.args, self.current_arg)
  endif

  let self.current_arg      = ''
  let self.current_arg_type = 'normal'
endfunction

" Moves the parser to the next char and consumes the current
function! s:PushChar() dict
  let self.current_arg .= self.body[0]
  call self.Next()
endfunction

" Moves the parser to the next char without consuming it.
function! s:Next() dict
  let self.body  = strpart(self.body, 1)
  let self.index = self.index + 1
endfunction

" Finds the current char in a:start_chars and jumps to its match in a:end_chars.
"
" Example:
"   call parser.JumpPair("([", ")]")
"
" This will parse matching round and square brackets.
"
" Note: nesting doesn't work properly if there's a string containing unmatched
" braces within the pair.
function! s:JumpPair(start_chars, end_chars) dict
  let char_index  = stridx(a:start_chars, self.body[0])
  let start_char  = a:start_chars[char_index]
  let target_char = a:end_chars[char_index]

  call self.PushChar()

  " prepare a stack for nested braces and the like
  let stack = 1
  let n     = 0
  let limit = len(self.body)

  " Note: if the start and end chars are the same (quotes, for example), this
  " will still work, because we're checking for the target_char before the
  " start_char
  while stack > 0 && n < limit
    let n = n + 1

    if self.body[n] == target_char
      let stack = stack - 1
    elseif self.body[n] == start_char
      let stack = stack + 1
    endif
  endwhile

  let self.current_arg .= strpart(self.body, 0, n)

  let self.body  = strpart(self.body, n)
  let self.index = self.index + n
endfunction

" Returns true if the parser has finished parsing the arguments.
function! s:Finished() dict
  return len(self.body) <= 0
endfunction

" If the last argument is a hash and no options have been parsed, splits the
" last argument and fills the options with it.
function! s:ExpandOptionHash() dict
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
function! s:AtFunctionEnd() dict
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
  let parser = s:Parser(a:start_index, a:end_index, a:line)
  call parser.Process()
  return [ a:start_index + 1, parser.index, parser.args, parser.opts ]
endfunction
