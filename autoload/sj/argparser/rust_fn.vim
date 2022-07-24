function! sj#argparser#rust_fn#Construct(start_index, end_index, line)
  let parser = sj#argparser#common#Construct(a:start_index, a:end_index, a:line)

  call extend(parser, {
        \ 'Process': function('sj#argparser#rust_fn#Process'),
        \ })

  return parser
endfunction

" Note: Differs from "rust_list" parser by the lack of "'", which could be
" used for reference lifetimes.
function! sj#argparser#rust_fn#Process() dict
  while !self.Finished()
    if self.body[0] == ','
      call self.PushArg()
      call self.Next()
      continue
    elseif self.body[0] =~ "[\"{\[(<]"
      call self.JumpPair("\"{[(<", "\"}])>")
    endif

    call self.PushChar()
  endwhile

  if len(sj#Trim(self.current_arg)) > 0
    call self.PushArg()
  endif
endfunction
