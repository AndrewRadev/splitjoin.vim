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

" Replace the normal mode motion given as the first parameter with the text
" given as the second parameter. Mostly just a wrapper for a normal! command
" with a paste, but doesn't pollute any registers.
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

" Execute the normal mode motion and return the text it marks.
"
" Note that the motion needs to include a visual mode key, like 'V', 'v' or
" 'gv'
function! sj#GetMotion(motion)
  let original_reg      = getreg('z')
  let original_reg_type = getregtype('z')

  exec 'normal! '.a:motion.'"zy'
  let text = @z

  call setreg('z', original_reg, original_reg_type)

  return text
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
