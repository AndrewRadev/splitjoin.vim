if exists("g:loaded_splitjoin") || &cp
  finish
endif

let g:loaded_splitjoin = '0.1.1' " version number
let s:keepcpo          = &cpo
set cpo&vim

" Public Interface:
" =================

command! SplitjoinSplit call s:Split()
command! SplitjoinJoin  call s:Join()

" Internal Functions:
" ===================

function! s:Split()
  if !exists('b:splitjoin_split_callbacks')
    return
  end

  " expand any folds under the cursor, or we might replace the wrong area
  silent! foldopen

  call sj#PushCursor()

  for callback in b:splitjoin_split_callbacks
    if call(callback, []) != 0
      break
    endif
  endfor

  call sj#PopCursor()
endfunction

function! s:Join()
  if !exists('b:splitjoin_join_callbacks')
    return
  end

  " expand any folds under the cursor, or we might replace the wrong area
  silent! foldopen

  call sj#PushCursor()

  for callback in b:splitjoin_join_callbacks
    if call(callback, []) != 0
      break
    endif
  endfor

  call sj#PopCursor()
endfunction

let &cpo = s:keepcpo
unlet s:keepcpo
