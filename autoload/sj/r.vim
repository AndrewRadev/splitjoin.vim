" Only real syntax that's interesting is cParen and cConditional
let s:skip = sj#SkipSyntax(['rComment'])

" function! sj#r#triml(text [, mask])
"
" A shorthand for trim with setting dir=1
"
function! sj#r#triml(text, ...)
  let inlen = len(a:text)
  let text = a:0 > 0
        \ ? trim(a:text, a:1, 1)
        \ : substitute(a:text, '^\s*', '', 'g')
  return [text, inlen - len(text)]
endfunction

" function! sj#r#MoveCursor(lines, cols)
"
" Reposition cursor given relative lines offset and columns from the start of
" the line
"
function! sj#r#MoveCursor(lines, cols)
  let y = a:lines > 0 ? a:lines . 'j^' : a:lines < 0 ? a:lines . 'k^' : ''
  let x = a:cols  > 0 ? a:cols  . 'l'  : a:cols  < 0 ? a:cols  . 'h'  : ''
  let motion = y . x
  if len(motion)
    execute 'silent normal! ' . motion
  endif
endfunction

" function! sj#r#ParseJsonObject(text)
"
" Wrapper around sj#argparser#js#Construct to simply parse a given string
"
function! sj#r#ParseJsonObject(text)
  let parser = sj#argparser#js#Construct(0, len(a:text), a:text)
  call parser.Process()
  return parser.args
endfunction

" function! sj#r#ParseFromMotion(motion)
"
" Parse a json object from the visual selection of a given normal-mode motion
" string
"
function! sj#r#ParseJsonFromMotion(motion)
  let text = sj#GetMotion(a:motion)
  return sj#r#ParseJsonObject(text)
endfunction

" function! sj#r#GetTextRange(start, end)
"
" Get the text between positions marked by getpos("start") and getpos("end")
function! sj#r#GetTextRange(start, end)
  let text = sj#GetByPosition(getpos(a:start), getpos(a:end))
  let lines = split(text, "\n")

  return lines
endfunction

" function! sj#r#IsValidSelection(motion)
"
" Test whether a visual selection contains more than a single character after
" performing the given normal-mode motion string
"
function! sj#r#IsValidSelection(motion)
  call sj#PushCursor()
  execute "silent normal! " . a:motion . "\<esc>"
  execute "silent normal! \<esc>"
  let is_valid = getpos("'<") != getpos("'>")
  call sj#PopCursor()
  return is_valid
endfunction

" function! sj#r#ReplaceMotionPreserveCursor(motion, lines [, inserts [, mask]]) {{{2
"
" Replace the normal mode "motion" with a list of "lines", separated by line
" breaks, and optionally "inserts" characters, while making a best attempt at
" preserving the cursor's location within the text block if it's replaced with
" similar text. Optionally, a "mask" can be provided which is a boolean list
" indication which text in "lines" originate as part of the original text of the
" visual selection.
"
function! sj#r#ReplaceMotionPreserveCursor(motion, rep, ...)
  " default to interpretting all lines of text as originally from text to replace
  let rep = a:rep
  let mask = a:0 > 2 ? a:2 : repeat([1], len(a:rep))

  " do motion and get bounds & text
  call sj#PushCursor()
  execute "silent normal! " . a:motion . "\<esc>"
  execute "silent normal! \<esc>"
  call sj#PopCursor()
  let ini = map(sj#r#GetTextRange("'<", "."), {k, v -> sj#r#triml(v)[0]})

  " do replacement
  let body = join(a:rep, "\n")
  call sj#ReplaceMotion(a:motion, body)

  " go back to start of selection
  silent normal! `<

  " try to reconcile initial selection against replacement lines
  let [cursory, cursorx] = [0, 0]
  while len(ini) && len(rep)
    " rep[0] (next replacement line) should be present in initial selection
    if mask[0]
      let i = stridx(ini[0], rep[0])
      let j = stridx(rep[0], ini[0])
      if i >= 0
        " if an entire line of the replacement text found in initial then we'll
        " need our cursor to move to the next line if more lines are insered
        let [ini[0], ws] = sj#r#triml(ini[0][i+len(rep[0]):])
        let cursorx += i + len(rep[0])
        let ini = len(ini[0]) ? ini : ini[1:]
        let rep = rep[1:]
        if len(ini)
          let cursory += 1
          let cursorx = 0
        endif
      elseif j >= 0
        " if an entire line of the initial is found in the replacement then
        " we'll need our cursor to move rightward through length of the initial
        let [rep[0], ws] = sj#r#triml(rep[0][j+len(ini[0]):])
        let cursorx += j + len(ini[0])
        let ini = ini[1:]
        let cursorx += (len(ini) && len(ini[0]) ? ws : 0)
      else
        let ini = []
      endif
      " continue to next rep (replacement line)
    else
      let rep = rep[1:]
    endif
  endwhile

  call sj#r#MoveCursor(cursory, max([cursorx-1, 0]))
  call sj#PushCursor()
endfunction

" function! sj#r#SplitFuncall()
"
" Split the R function call if the cursor lies within the arguments of a
" function call
"
function! sj#r#SplitFuncall()
  if !sj#r#IsValidSelection("va(")
    return 0
  endif

  call sj#PushCursor()
  let items = sj#r#ParseJsonFromMotion("va(\<esc>vi(")
  let items = map(items, {k, v -> v . (k+1 < len(items) ? "," : "")})

  if g:r_indent_align_args && len(items)
    let items[0]  = "(" . items[0]
    let items[-1] = items[-1] . ")"
    let lines = items
  else
    let lines = ["("] + items + [")"]
  endif

  call sj#PopCursor()
  call sj#r#ReplaceMotionPreserveCursor('va(', lines)

  return 1
endfunction

" function! sj#r#JoinFuncall()
"
" Join an R function call if the cursor lies within the arguments of a
" function call
"
function! sj#r#JoinFuncall()
  if !sj#r#IsValidSelection("va(")
    return 0
  endif

  call sj#PushCursor()
  let items = sj#r#ParseJsonFromMotion("va(\<esc>vi(")

  " clean up unwanted spaces around parens which can occur during nested joins
  let text = join(items, ", ")
  let text = substitute(text, '(\s', '(', 'g')
  let text = substitute(text, '\s)', ')', 'g')

  call sj#PopCursor()
  call sj#r#ReplaceMotionPreserveCursor("va(", ["(" . text . ")"])

  return 1
endfunction
