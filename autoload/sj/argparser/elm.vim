" Constructor:
" ============

function! sj#argparser#elm#Construct(start_index, end_index, line)
  let parser = sj#argparser#common#Construct(a:start_index, a:end_index, a:line)

  call extend(parser, {
        \ 'Process':          function('sj#argparser#elm#Process'),
        \ 'AtFunctionEnd':    function('sj#argparser#elm#AtFunctionEnd'),
        \ 'ExpandOptionHash': function('sj#argparser#elm#ExpandOptionHash'),
        \ })

  return parser
endfunction

" Methods:
" ========

function! sj#argparser#elm#Process() dict
  while !self.Finished()
    if self.body[0] == ','
      call self.PushArg()
      call self.Next()
      continue
    elseif self.AtFunctionEnd()
      break
    elseif self.body[0] =~ "[\"'{\[(]"
      call self.JumpPair("\"'{[(", "\"'}])")
    endif

    call self.PushChar()
  endwhile

  if len(self.current_arg) > 0
    call self.PushArg()
  endif
endfunction

" Returns true if the parser is at the list's end (a closing bracket).
function! sj#argparser#elm#AtFunctionEnd() dict
  if self.body[0] == ']'
    return 1
  endif

  return 0
endfunction

" Public functions:
" =================


function! sj#argparser#elm#ParseArguments(start_index, end_index, line)
  let parser = sj#argparser#elm#Construct(a:start_index, a:end_index, a:line)
  call parser.Process()
  return [ a:start_index, parser.index, parser.args ]
endfunction
