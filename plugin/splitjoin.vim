if exists("g:loaded_splitjoin") || &cp
  finish
endif

let g:loaded_splitjoin = '0.2.2' " version number
let s:keepcpo          = &cpo
set cpo&vim

if !exists('g:splitjoin_normalize_whitespace')
  let g:splitjoin_normalize_whitespace = 0
endif

if !exists('g:splitjoin_align')
  let g:splitjoin_align = 0
end

if !exists('g:splitjoin_ruby_curly_braces')
  let g:splitjoin_ruby_curly_braces = 1
end

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
      silent! call repeat#set(":SplitjoinSplit\<cr>")
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
      silent! call repeat#set(":SplitjoinJoin\<cr>")
      break
    endif
  endfor

  call sj#PopCursor()
endfunction

let &cpo = s:keepcpo
unlet s:keepcpo
