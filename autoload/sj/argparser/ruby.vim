" Constructor:
" ============

function! sj#argparser#ruby#Construct(start_index, end_index, line)
  let parser = sj#argparser#common#Construct(a:start_index, a:end_index, a:line)

  call extend(parser, {
        \ 'hash_type': '',
        \
        \ 'Process':          function('sj#argparser#ruby#Process'),
        \ 'PushArg':          function('sj#argparser#ruby#PushArg'),
        \ 'AtFunctionEnd':    function('sj#argparser#ruby#AtFunctionEnd'),
        \ 'ExpandOptionHash': function('sj#argparser#ruby#ExpandOptionHash'),
        \ })

  return parser
endfunction

" Methods:
" ========

function! sj#argparser#ruby#Process() dict
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
      if delimiter =~ '[[({<]'
        call self.JumpPair('[({<', '])}>')
      else
        call self.JumpPair(delimiter, delimiter)
      endif
    elseif self.body =~ '^=>'
      let self.current_arg_type = 'option'
      if sj#BlankString(self.hash_type)
        let self.hash_type = 'classic'
      elseif self.hash_type == 'new'
        let self.hash_type = 'mixed'
      endif
    elseif self.body =~ '^\k:'
      let self.current_arg_type = 'option'
      if sj#BlankString(self.hash_type)
        let self.hash_type = 'new'
      elseif self.hash_type == 'classic'
        let self.hash_type = 'mixed'
      endif
      call self.PushChar()
    endif

    call self.PushChar()
  endwhile

  if len(self.current_arg) > 0
    call self.PushArg()
  endif
  call self.ExpandOptionHash()
endfunction

" Pushes the current argument either to the args or opts stack and initializes
" a new one.
function! sj#argparser#ruby#PushArg() dict
  if self.current_arg_type == 'option'
    call add(self.opts, sj#Trim(self.current_arg))
  else
    call add(self.args, sj#Trim(self.current_arg))
  endif

  let self.current_arg      = ''
  let self.current_arg_type = 'normal'
endfunction

" If the last argument is a hash and no options have been parsed, splits the
" last argument and fills the options with it.
function! sj#argparser#ruby#ExpandOptionHash() dict
  if len(self.opts) <= 0 && len(self.args) > 0
    " then try parsing the last parameter
    let last = self.args[-1]
    let hash_pattern = '^{\(.*\(=>\|\k:\).*\)}$'

    if last =~ hash_pattern
      " then it seems to be a hash, expand it
      call remove(self.args, -1)

      let hash = sj#ExtractRx(last, hash_pattern, '\1')

      let [_from, _to, _args, opts, hash_type] = sj#argparser#ruby#ParseArguments(0, -1, hash)
      call extend(self.opts, opts)
      let self.hash_type = hash_type
    endif
  endif
endfunction

" Returns true if the parser is at the function's end, either because of a
" closing brace, a "do" clause or a "%>".
function! sj#argparser#ruby#AtFunctionEnd() dict
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

function! sj#argparser#ruby#LocateFunction()
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
    let from      = col('.') - 1
    let to        = -1 " we're not sure about the end right now
    let delimiter = getline('.')[col('.') - 2]

    if delimiter == '('
      let function_type = 'with_round_braces'
    else
      let function_type = 'with_spaces'
    endif

    return [from, to, function_type]
  endif

  return [-1, -1, '']
endfunction

function! sj#argparser#ruby#LocateHash()
  return sj#LocateBracesOnLine('{', '}')
endfunction

function! sj#argparser#ruby#ParseArguments(start_index, end_index, line)
  let parser = sj#argparser#ruby#Construct(a:start_index, a:end_index, a:line)
  call parser.Process()
  return [ a:start_index + 1, parser.index, parser.args, parser.opts, parser.hash_type ]
endfunction
