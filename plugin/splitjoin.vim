if exists("g:loaded_splitjoin") || &cp
  finish
endif

let g:loaded_splitjoin = '0.6.0' " version number
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

if !exists('g:splitjoin_ruby_heredoc_type')
  let g:splitjoin_ruby_heredoc_type = '<<-' " can be one of '<<-', '<<'
endif

if !exists('g:splitjoin_coffee_suffix_if_clause')
  let g:splitjoin_coffee_suffix_if_clause = 1
endif

if !exists('g:splitjoin_perl_brace_on_same_line')
  let g:splitjoin_perl_brace_on_same_line = 1
endif

if !exists('g:splitjoin_join_mapping')
  let g:splitjoin_join_mapping = 'gJ'
endif

if !exists('g:splitjoin_split_mapping')
  let g:splitjoin_split_mapping = 'gS'
endif

" Public Interface:
" =================

command! SplitjoinSplit call s:Split()
command! SplitjoinJoin  call s:Join()

if g:splitjoin_join_mapping != ''
  exe 'nnoremap <silent> '.g:splitjoin_join_mapping.' :<c-u>call <SID>Mapping(g:splitjoin_join_mapping, "SplitjoinJoin")<cr>'
endif

if g:splitjoin_split_mapping != ''
  exe 'nnoremap <silent> '.g:splitjoin_split_mapping.' :<c-u>call <SID>Mapping(g:splitjoin_split_mapping, "SplitjoinSplit")<cr>'
endif

" Internal Functions:
" ===================

function! s:Split()
  if !exists('b:splitjoin_split_callbacks')
    return
  end

  " expand any folds under the cursor, or we might replace the wrong area
  silent! foldopen

  let saved_view = winsaveview()

  for callback in b:splitjoin_split_callbacks
    try
      call sj#PushCursor()

      if call(callback, [])
        silent! call repeat#set(":SplitjoinSplit\<cr>")
        break
      endif

    finally
      call sj#PopCursor()
    endtry
  endfor

  call winrestview(saved_view)
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

      if call(callback, [])
        silent! call repeat#set(":SplitjoinJoin\<cr>")
        break
      endif

    finally
      call sj#PopCursor()
    endtry
  endfor
endfunction

function! s:Mapping(mapping, command)
  if !v:count
    let tick = b:changedtick
    exe a:command
    if tick == b:changedtick
      execute 'normal! '.a:mapping
    endif
  else
    execute 'normal! '.v:count.a:mapping
  endif
endfunction

let &cpo = s:keepcpo
unlet s:keepcpo
