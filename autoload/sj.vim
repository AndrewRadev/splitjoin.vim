" Adds the current cursor position to a stack
function! sj#PushCursor()
  if !exists('b:cursor_position_stack')
    let b:cursor_position_stack = []
  endif

  call add(b:cursor_position_stack, getpos('.'))
endfunction

" Restores the cursor to the latest position in the cursor stack, as added from
" the sj#PushCursor function
function! sj#PopCursor()
  if !exists('b:cursor_position_stack')
    let b:cursor_position_stack = []
  endif

  call setpos('.', remove(b:cursor_position_stack, -1))
endfunction

" Returns the last saved cursor position
function! sj#PeekCursor()
  return b:cursor_position_stack[-1]
endfunction

" Replace the normal mode 'motion' with 'text' Mostly just a wrapper for a
" normal! command with a paste, but doesn't pollute any registers.
"
" The third parameter is optional -- if it's truthy (it is, by default), the
" result is reindented, else it's not.
"
" Example: call sj#ReplaceMotion('Va{', 'some text')
"
" Note that the motion needs to include a visual mode key, like 'V', 'v' or
" 'gv'
function! sj#ReplaceMotion(motion, text, ...)
  let original_reg      = getreg('z')
  let original_reg_type = getregtype('z')

  if a:0 > 0
    let reindent = a:0
  else
    let reindent = 1
  end

  let @z = a:text
  exec 'normal! '.a:motion.'"zp'
  normal! gv=

  call setreg('z', original_reg, original_reg_type)
endfunction

" Replace the area defined by the 'start' and 'end' lines with 'text'
function! sj#ReplaceLines(start, end, text, ...)
  if a:0 > 0
    let reindent = a:0
  else
    let reindent = 1
  end

  let interval = a:end - a:start

  return sj#ReplaceMotion(a:start.'GV'.interval.'j', a:text, reindent)
endfunction

" Execute the normal mode motion and return the text it marks.
"
" Note that the motion needs to include a visual mode key, like 'V', 'v' or
" 'gv'
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

" Retrieve the lines from a:start to a:end and return them as a list. Simply a
" wrapper for getbufline for the moment.
function! sj#GetLines(start, end)
  return getbufline('%', a:start, a:end)
endfunction

" Trimming functions. Should be obvious.
function! sj#Ltrim(s)
	return substitute(a:s, '^\_s\+', '', '')
endfunction
function! sj#Rtrim(s)
	return substitute(a:s, '\_s\+$', '', '')
endfunction
function! sj#Trim(s)
  return sj#Rtrim(sj#Ltrim(a:s))
endfunction

" Extract a regex match from a string. Ordinarily, substitute() would be used
" for this, but it's a bit too cumbersome for extracting a particular grouped
" match.
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
