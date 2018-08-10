if exists("g:loaded_splitjoin") || &cp
  finish
endif

let g:loaded_splitjoin = '0.8.0' " version number
let s:keepcpo          = &cpo
set cpo&vim

" Defaults:
" =========

call sj#settings#SetDefault('quiet',                                   0)
call sj#settings#SetDefault('normalize_whitespace',                    1)
call sj#settings#SetDefault('trailing_comma',                          0)
call sj#settings#SetDefault('align',                                   0)
call sj#settings#SetDefault('curly_brace_padding',                     1)
call sj#settings#SetDefault('ruby_curly_braces',                       1)
call sj#settings#SetDefault('ruby_heredoc_type',                       '<<~')
call sj#settings#SetDefault('ruby_trailing_comma',                     0)
call sj#settings#SetDefault('ruby_hanging_args',                       1)
call sj#settings#SetDefault('ruby_do_block_split',                     1)
call sj#settings#SetDefault('ruby_options_as_arguments',               0)
call sj#settings#SetDefault('coffee_suffix_if_clause',                 1)
call sj#settings#SetDefault('perl_brace_on_same_line',                 1)
call sj#settings#SetDefault('php_method_chain_full',                   0)
call sj#settings#SetDefault('python_brackets_on_separate_lines',       0)
call sj#settings#SetDefault('handlebars_closing_bracket_on_same_line', 0)
call sj#settings#SetDefault('handlebars_hanging_arguments',            0)
call sj#settings#SetDefault('html_attribute_bracket_on_new_line',      0)

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

nnoremap <silent> <plug>SplitjoinSplit :<c-u>call <SID>Split()<cr>
nnoremap <silent> <plug>SplitjoinJoin  :<c-u>call <SID>Join()<cr>

if g:splitjoin_join_mapping != ''
  exe 'nnoremap <silent> '.g:splitjoin_join_mapping.' :<c-u>call <SID>Mapping(g:splitjoin_join_mapping, "<SID>Join")<cr>'
endif

if g:splitjoin_split_mapping != ''
  exe 'nnoremap <silent> '.g:splitjoin_split_mapping.' :<c-u>call <SID>Mapping(g:splitjoin_split_mapping, "<SID>Split")<cr>'
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
  let saved_whichwrap = &whichwrap
  set whichwrap-=l

  if !sj#settings#Read('quiet') | echo "Splitjoin: Working..." | endif
  for callback in b:splitjoin_split_callbacks
    try
      call sj#PushCursor()

      if call(callback, [])
        silent! call repeat#set("\<plug>SplitjoinSplit")
        let &whichwrap = saved_whichwrap
        if !sj#settings#Read('quiet')
          " clear progress message
          redraw | echo ""
        endif
        return 1
      endif

    finally
      call sj#PopCursor()
    endtry
  endfor

  call winrestview(saved_view)
  let &whichwrap = saved_whichwrap
  if !sj#settings#Read('quiet')
    " clear progress message
    redraw | echo ""
  endif
  return 0
endfunction

function! s:Join()
  if !exists('b:splitjoin_join_callbacks')
    return
  end

  " expand any folds under the cursor, or we might replace the wrong area
  silent! foldopen

  let saved_view = winsaveview()
  let saved_whichwrap = &whichwrap
  set whichwrap-=l

  if !sj#settings#Read('quiet') | echo "Splitjoin: Working..." | endif
  for callback in b:splitjoin_join_callbacks
    try
      call sj#PushCursor()

      if call(callback, [])
        silent! call repeat#set("\<plug>SplitjoinJoin")
        let &whichwrap = saved_whichwrap
        if !sj#settings#Read('quiet')
          " clear progress message
          redraw | echo ""
        endif
        return 1
      endif

    finally
      call sj#PopCursor()
    endtry
  endfor

  call winrestview(saved_view)
  let &whichwrap = saved_whichwrap
  if !sj#settings#Read('quiet')
    " clear progress message
    redraw | echo ""
  endif
  return 0
endfunction

" Used to create a mapping for the given a:function that falls back to the
" built-in key sequence (a:mapping) if the function returns 0, meaning it
" didn't do anything.
"
function! s:Mapping(mapping, function)
  if !v:count
    if !call(a:function, [])
      execute 'normal! '.a:mapping
    endif
  else
    execute 'normal! '.v:count.a:mapping
  endif
endfunction

let &cpo = s:keepcpo
unlet s:keepcpo
