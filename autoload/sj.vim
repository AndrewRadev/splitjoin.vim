" vim: foldmethod=marker

" Cursor stack manipulation {{{1
"
" In order to make the pattern of saving the cursor and restoring it
" afterwards easier, these functions implement a simple cursor stack. The
" basic usage is:
"
"   call sj#PushCursor()
"   " Do stuff that move the cursor around
"   call sj#PopCursor()

" function! sj#PushCursor() {{{2
"
" Adds the current cursor position to the cursor stack.
function! sj#PushCursor()
  if !exists('b:cursor_position_stack')
    let b:cursor_position_stack = []
  endif

  call add(b:cursor_position_stack, getpos('.'))
endfunction

" function! sj#PopCursor() {{{2
"
" Restores the cursor to the latest position in the cursor stack, as added
" from the sj#PushCursor function. Removes the position from the stack.
function! sj#PopCursor()
  if !exists('b:cursor_position_stack')
    let b:cursor_position_stack = []
  endif

  call setpos('.', remove(b:cursor_position_stack, -1))
endfunction

" function! sj#PeekCursor() {{{2
"
" Returns the last saved cursor position from the cursor stack.
" Note that if the cursor hasn't been saved at all, this will raise an error.
function! sj#PeekCursor()
  return b:cursor_position_stack[-1]
endfunction

" Text replacement {{{1
"
" Vim doesn't seem to have a whole lot of functions to aid in text replacement
" within a buffer. The ":normal!" command usually works just fine, but it
" could be difficult to maintain sometimes. These functions encapsulate a few
" common patterns for this.

" function! sj#ReplaceMotion(motion, text) {{{2
"
" Replace the normal mode "motion" with "text". This is mostly just a wrapper
" for a normal! command with a paste, but doesn't pollute any registers.
"
" Example: call sj#ReplaceMotion('Va{', 'some text')
"
" Note that the motion needs to include a visual mode key, like "V", "v" or
" "gv"
function! sj#ReplaceMotion(motion, text)
  let original_reg      = getreg('z')
  let original_reg_type = getregtype('z')

  let @z = a:text
  exec 'normal! '.a:motion.'"zp'
  normal! gv=

  call setreg('z', original_reg, original_reg_type)
endfunction

" function! sj#ReplaceLines(start, end, text) {{{2
"
" Replace the area defined by the 'start' and 'end' lines with 'text'.
function! sj#ReplaceLines(start, end, text)
  let interval = a:end - a:start

  return sj#ReplaceMotion(a:start.'GV'.interval.'j', a:text)
endfunction

" function! sj#ReplaceCols(start, end, text) {{{2
"
" Replace the area defined by the 'start' and 'end' columns on the current
" line with 'text'
"
" TODO Multibyte characters break it
function! sj#ReplaceCols(start, end, text)
  let start    = a:start - 1
  let interval = a:end - a:start

  if start > 0
    let motion = '0'.start.'lv'.interval.'l'
  else
    let motion = '0v'.interval.'l'
  endif

  return sj#ReplaceMotion(motion, a:text)
endfunction

" Text retrieval {{{1
"
" These functions are similar to the text replacement functions, only retrieve
" the text instead.

" function! sj#GetMotion(motion) {{{2
"
" Execute the normal mode motion "motion" and return the text it marks.
"
" Note that the motion needs to include a visual mode key, like "V", "v" or
" "gv"
function! sj#GetMotion(motion)
  call sj#PushCursor()

  let original_reg      = getreg('z')
  let original_reg_type = getregtype('z')

  exec 'normal! '.a:motion.'"zy'
  let text = @z

  call setreg('z', original_reg, original_reg_type)
  call sj#PopCursor()

  return text
endfunction

" function! sj#GetLines(start, end) {{{2
"
" Retrieve the lines from "start" to "end" and return them as a list. This is
" simply a wrapper for getbufline for the moment.
function! sj#GetLines(start, end)
  return getbufline('%', a:start, a:end)
endfunction

" function! sj#GetLines(start, end) {{{2
"
" Retrieve the text from columns "start" to "end" on the current line.
function! sj#GetCols(start, end)
  return strpart(getline('.'), a:start - 1, a:end - a:start + 1)
endfunction

" String functions {{{1
" Various string manipulation utility functions
function! sj#BlankString(s)
  return (a:s =~ '^\s*$')
endfunction

" Surprisingly, Vim doesn't seem to have a "trim" function. In any case, these
" should be fairly obvious.
function! sj#Ltrim(s)
  return substitute(a:s, '^\_s\+', '', '')
endfunction
function! sj#Rtrim(s)
  return substitute(a:s, '\_s\+$', '', '')
endfunction
function! sj#Trim(s)
  return sj#Rtrim(sj#Ltrim(a:s))
endfunction

" Regex helpers {{{1

" function! sj#ExtractRx(expr, pat, sub)
"
" Extract a regex match from a string. Ordinarily, substitute() would be used
" for this, but it's a bit too cumbersome for extracting a particular grouped
" match. Example usage:
"
"   sj#ExtractRx('foo:bar:baz', ':\(.*\):', '\1') == 'bar'
"
function! sj#ExtractRx(expr, pat, sub)
  let rx = a:pat

  if stridx(a:pat, '^') != 0
    let rx = '^.*'.rx
  endif

  if strridx(a:pat, '$') + 1 != strlen(a:pat)
    let rx = rx.'.*$'
  endif

  return substitute(a:expr, rx, a:sub, '')
endfunction

" Splitjoin-specific helpers {{{1

" These functions are not general-purpose, but can be used all around the
" plugin disregarding filetype, so they have no place in the specific autoload
" files.

function! sj#Align(from, to, type)
  if exists('g:tabular_loaded')
    call sj#PushCursor()
    call s:Tabularize(a:from, a:to, a:type)
    call sj#PopCursor()
  elseif exists('g:loaded_AlignPlugin')
    call sj#PushCursor()
    call s:Align(a:from, a:to, a:type)
    call sj#PopCursor()
  endif
endfunction

function! s:Tabularize(from, to, type)
  call cursor(a:from, 0)

  if a:type == 'ruby_hash'
    let pattern = '^[^=>]*\zs=>'
  elseif a:type == 'css_declaration'
    let pattern = ':\s*\zs\s/l0'
  else
    return
  endif

  exe "normal! V".(a:to - a:from)."j:Tabularize/".pattern."\<cr>"
endfunction

function! s:Align(from, to, type)
  call cursor(a:from, 0)

  if a:type == 'ruby_hash'
    let pattern = 'l: =>'
  elseif a:type == 'css_declaration'
    let pattern = 'lp0W0 :\s*\zs'
  else
    return
  endif

  exe "normal! V".(a:to - a:from)."j:Align! ".pattern."\<cr>"
endfunction
