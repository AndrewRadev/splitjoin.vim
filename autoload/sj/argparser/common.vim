" Constructor:
" ============

function! sj#argparser#common#Construct(start_index, end_index, line)
  let parser = {
        \ 'args':             [],
        \ 'opts':             [],
        \ 'body':             a:line,
        \ 'index':            a:start_index,
        \ 'current_arg':      '',
        \ 'current_arg_type': 'normal',
        \
        \ 'Process':       function('sj#argparser#common#Process'),
        \ 'PushArg':       function('sj#argparser#common#PushArg'),
        \ 'PushChar':      function('sj#argparser#common#PushChar'),
        \ 'Next':          function('sj#argparser#common#Next'),
        \ 'JumpPair':      function('sj#argparser#common#JumpPair'),
        \ 'AtFunctionEnd': function('sj#argparser#common#AtFunctionEnd'),
        \ 'Finished':      function('sj#argparser#common#Finished'),
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

function! sj#argparser#common#Process() dict
  throw "Not implemented"

  " " Implementation might go something like this:
  "
  " while !self.Finished()
  "   if self.body[0] == ','
  "     call self.PushArg()
  "     call self.Next()
  "     continue
  "   elseif self.AtFunctionEnd()
  "     break
  "   else
  "     " ...
  "   endif

  "   call self.PushChar()
  " endwhile

  " if len(self.current_arg) > 0
  "   call self.PushArg()
  " endif
endfunction

" Pushes the current argument to the args and initializes a new one.
function! sj#argparser#common#PushArg() dict
  call add(self.args, sj#Trim(self.current_arg))

  let self.current_arg      = ''
  let self.current_arg_type = 'normal'
endfunction

" Moves the parser to the next char and consumes the current
function! sj#argparser#common#PushChar() dict
  let self.current_arg .= self.body[0]
  call self.Next()
endfunction

" Moves the parser to the next char without consuming it.
function! sj#argparser#common#Next() dict
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
function! sj#argparser#common#JumpPair(start_chars, end_chars) dict
  let char_index  = stridx(a:start_chars, self.body[0])
  let start_char  = a:start_chars[char_index]
  let target_char = a:end_chars[char_index]

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
function! sj#argparser#common#Finished() dict
  return len(self.body) <= 0
endfunction

" Returns true if the parser is at the function's end
function! sj#argparser#common#AtFunctionEnd() dict
  return (self.body[0] == ')')
endfunction
