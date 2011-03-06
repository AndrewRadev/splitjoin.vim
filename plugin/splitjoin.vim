command! SplitjoinSplit call s:Split()
function! s:Split()
  if !exists('b:splitjoin_split_callbacks')
    return
  end

  call sj#PushCursor()

  for callback in b:splitjoin_split_callbacks
    if call(callback, []) == 1
      break
    endif
  endfor

  call sj#PopCursor()
endfunction

command! SplitjoinJoin call s:Join()
function! s:Join()
  if !exists('b:splitjoin_join_callbacks')
    return
  end

  call sj#PushCursor()

  for callback in b:splitjoin_join_callbacks
    if call(callback, []) == 1
      break
    endif
  endfor

  call sj#PopCursor()
endfunction
