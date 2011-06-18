" Data structure:
" ===============

" Resets the parser.
function! s:Init(start_index, end_index, line) dict
  let self.args             = []
  let self.opts             = []
  let self.index            = a:start_index
  let self.current_arg      = ''
  let self.current_arg_type = 'normal'

  let self.body = a:line
  if a:start_index > 0
    let self.body = strpart(self.body, a:start_index)
  endif
  if a:end_index > 0
    let self.body = strpart(self.body, 0, a:end_index - a:start_index)
  endif
endfunction

function! s:Process() dict
  while !self.finished()
    if self.body[0] == ','
      call self.push_arg()
      call self.next()
      continue
    elseif self.at_function_end()
      break
    elseif self.body[0] =~ "[\"'{\[`(/]"
      call self.jump_pair("\"'{[`(/", "\"'}]`)/")
    elseif self.body[0] == '%'
      call self.push_char()
      if self.body[0] =~ '[qQrswWx]'
        call self.push_char()
      endif
      let delimiter = self.body[0]
      call self.jump_pair(delimiter, delimiter)
    elseif self.body =~ '^=>'
      let self.current_arg_type = 'option'
      call self.push_char()
    endif

    call self.push_char()
  endwhile

  if len(self.current_arg) > 0
    call self.push_arg()
  endif
  call self.expand_option_hash()

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
  call self.next()
endfunction

" Moves the parser to the next char without consuming it.
function! s:Next() dict
  let self.body  = strpart(self.body, 1)
  let self.index = self.index + 1
endfunction

" Finds the current char in a:start_chars and jumps to its match in a:end_chars.
"
" Example:
"   call parser.jump_pair("([", ")]")
"
" This will parse matching round and square brackets.
"
" Note: nesting doesn't work properly if there's a string containing unmatched
" braces within the pair.
function! s:JumpPair(start_chars, end_chars) dict
  let char_index  = stridx(a:start_chars, self.body[0])
  let start_char  = a:start_chars[char_index]
  let target_char = a:end_chars[char_index]

  call self.push_char()

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

let s:parser = {
      \ 'args':             [],
      \ 'opts':             [],
      \ 'body':             '',
      \ 'index':            0,
      \ 'current_arg':      '',
      \ 'current_arg_type': 'normal',
      \
      \ 'init':               function("s:Init"),
      \ 'process':            function("s:Process"),
      \ 'push_arg':           function("s:PushArg"),
      \ 'push_char':          function("s:PushChar"),
      \ 'next':               function("s:Next"),
      \ 'jump_pair':          function("s:JumpPair"),
      \ 'at_function_end':    function("s:AtFunctionEnd"),
      \ 'finished':           function("s:Finished"),
      \ 'expand_option_hash': function("s:ExpandOptionHash"),
      \ }

" Constructor:
" ============

function! s:Parser(start_index, end_index, line)
  let parser = deepcopy(s:parser)
  call parser.init(a:start_index, a:end_index, a:line)
  return parser
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
  call parser.process()
  return [ a:start_index + 1, parser.index, parser.args, parser.opts ]
endfunction
