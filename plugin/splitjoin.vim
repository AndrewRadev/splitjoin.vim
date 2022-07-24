if exists("g:loaded_splitjoin") || &cp
  finish
endif

let g:loaded_splitjoin = '1.1.0' " version number
let s:keepcpo          = &cpo
set cpo&vim

" Defaults:
" =========

if !exists('g:splitjoin_join_mapping')
  let g:splitjoin_join_mapping = 'gJ'
endif

if !exists('g:splitjoin_split_mapping')
  let g:splitjoin_split_mapping = 'gS'
endif

" Public Interface:
" =================

command! SplitjoinSplit call sj#Split()
command! SplitjoinJoin  call sj#Join()

nnoremap <silent> <plug>SplitjoinSplit :<c-u>call sj#Split()<cr>
nnoremap <silent> <plug>SplitjoinJoin  :<c-u>call sj#Join()<cr>

if g:splitjoin_join_mapping != ''
  exe 'nnoremap <silent> '.g:splitjoin_join_mapping.' :<c-u>call <SID>Mapping(g:splitjoin_join_mapping, "sj#Join")<cr>'
endif

if g:splitjoin_split_mapping != ''
  exe 'nnoremap <silent> '.g:splitjoin_split_mapping.' :<c-u>call <SID>Mapping(g:splitjoin_split_mapping, "sj#Split")<cr>'
endif

" Internal Functions:
" ===================

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
