if exists("g:loaded_splitjoin") || &cp
  finish
endif

let g:loaded_splitjoin = '0.5.2' " version number
let s:keepcpo          = &cpo
set cpo&vim

" Defaults:
" =========

if !exists('g:splitjoin_normalize_whitespace')
  let g:splitjoin_normalize_whitespace = 0
endif

if !exists('g:splitjoin_align')
  let g:splitjoin_align = 0
end

if !exists('g:splitjoin_ruby_curly_braces')
  let g:splitjoin_ruby_curly_braces = 1
end

if !exists('g:splitjoin_coffee_suffix_if_clause')
  let g:splitjoin_coffee_suffix_if_clause = 1
endif

if !exists('g:splitjoin_perl_brace_on_same_line')
  let g:splitjoin_perl_brace_on_same_line = 1
endif

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

  for callback in b:splitjoin_split_callbacks
    try
      call sj#PushCursor()

      if call(callback, []) != 0
        silent! call repeat#set(":SplitjoinSplit\<cr>")
        break
      endif

    finally
      call sj#PopCursor()
    endtry
  endfor
endfunction

function! s:Join()
  if !exists('b:splitjoin_join_callbacks')
    return
  end

  " expand any folds under the cursor, or we might replace the wrong area
  silent! foldopen

  for callback in b:splitjoin_join_callbacks
    try
      call sj#PushCursor()

      if call(callback, []) != 0
        silent! call repeat#set(":SplitjoinJoin\<cr>")
        break
      endif

    finally
      call sj#PopCursor()
    endtry
  endfor
endfunction

let &cpo = s:keepcpo
unlet s:keepcpo
