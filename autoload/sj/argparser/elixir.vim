function! sj#argparser#elixir#LocateFunction()
  call sj#PushCursor()
  let start_col = col('.')
  let skip = sj#SkipSyntax(['elixirString', 'elixirAtom'])

  " The first pattern matches functions with brackets and consists of the
  " following:
  "
  "   - a keyword
  "   - an opening round bracket
  "   - something that's not a comma and doesn't look like an operator
  "     (to avoid a few edge cases)
  "
  " (copied from ruby and tweaked)
  "
  let pattern = '\v(^|\s|\.|::)\k+\(\s*[^,=<>+-/*^%})\]]'
  let found = sj#SearchSkip(pattern, skip, 'bcW', line('.'))
  if found <= 0
    " try searching forward
    let found = sj#SearchSkip(pattern, skip, 'cW', line('.'))
  endif
  if found > 0
    " go to the end of the matching pattern
    call search(pattern, 'cWe', line('.'))
    " look for the starting bracket
    if sj#SearchSkip('\k\+\s*\zs(\s*\%#', skip, 'bcW', line('.'))
      let from = col('.') + 1
      normal! h%h
      let to = col('.')

      if sj#ColBetween(start_col, from - 1, to + 1)
        return [from, to]
      endif
    endif
  endif

  call sj#PopCursor()

  " The second pattern matches functions without brackets:
  "
  "   - a keyword
  "   - at least one space
  "   - something that's not a comma and doesn't look like an operator
  "     (to avoid a few edge cases)
  "
  " (copied from ruby and tweaked)
  "
  let pattern = '\v(^|\s|\.|::)\k+[?!]?\s+[^ ,=<>+-/*^%})\]]'
  let found = sj#SearchSkip(pattern, skip, 'bcW', line('.'))
  if found <= 0
    " try searching forward
    let found = sj#SearchSkip(pattern, skip, 'cW', line('.'))
  endif
  if found > 0
    " first, figure out the function name
    call search('\k\+', 'cW', line('.'))
    let function_start_col = col('.')

    " go to the end of the matching pattern
    call search(pattern, 'cWe', line('.'))

    let from = col('.')
    let to   = -1 " we're not sure about the end

    if sj#ColBetween(start_col, function_start_col - 1, col('$'))
      return [from, to]
    endif
  endif

  return [-1, -1]
endfunction

function! sj#argparser#elixir#Construct(start_index, end_index, line)
  let parser = sj#argparser#common#Construct(a:start_index, a:end_index, a:line)

  call extend(parser, {
        \ 'Process': function('sj#argparser#elixir#Process'),
        \ })

  return parser
endfunction

function! sj#argparser#elixir#Process() dict
  while !self.Finished()
    if self.body[0] == ','
      call self.PushArg()
      call self.Next()
      continue
    elseif self.body[0] =~ "[\"'{\[(/]"
      call self.JumpPair("\"'{[(/", "\"'}])/")
    endif

    call self.PushChar()
  endwhile

  if len(sj#Trim(self.current_arg)) > 0
    call self.PushArg()
  endif
endfunction
