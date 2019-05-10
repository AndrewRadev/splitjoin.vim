function! sj#argparser#rust#Construct(start_index, end_index, line)
  let parser = sj#argparser#common#Construct(a:start_index, a:end_index, a:line)

  call extend(parser, {
        \ 'Process': function('sj#argparser#rust#Process'),
        \ })

  return parser
endfunction

function! sj#argparser#rust#Process() dict
  while !self.Finished()
    if self.body[0] == ','
      call self.PushArg()
      call self.Next()
      continue
    elseif self.body =~ '^''\\\=.'''
      " then it's a char, not a lifetime, we can jump it
      call self.JumpPair("'", "'")
    elseif self.body[0] =~ '["{\[(|]'
      call self.JumpPair('"{[(|', '"}])|')
    endif

    call self.PushChar()
  endwhile

  if len(sj#Trim(self.current_arg)) > 0
    call self.PushArg()
  endif
endfunction
