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
"
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
  call setpos('.', remove(b:cursor_position_stack, -1))
endfunction

" function! sj#DropCursor() {{{2
"
" Discards the last saved cursor position from the cursor stack.
" Note that if the cursor hasn't been saved at all, this will raise an error.
function! sj#DropCursor()
  call remove(b:cursor_position_stack, -1)
endfunction

" Indenting {{{1
"
" Some languages don't have built-in support, and some languages have semantic
" indentation. In such cases, code blocks might need to be reindented
" manually.
"

" function! sj#SetIndent(start_lineno, end_lineno, indent) {{{2
" function! sj#SetIndent(lineno, indent)
"
" Sets the indent of the given line numbers to "indent" amount of whitespace.
" For now, works only with spaces, not with tabs.
"
function! sj#SetIndent(...)
  if a:0 == 3
    let start_lineno = a:1
    let end_lineno   = a:2
    let indent       = a:3
  elseif a:0 == 2
    let start_lineno = a:1
    let end_lineno   = a:1
    let indent       = a:2
  endif

  let whitespace = repeat(' ', indent)

  exe start_lineno.','.end_lineno.'s/^\s*/'.whitespace

  " Don't leave a history entry
  call histdel('search', -1)
  let @/ = histget('search', -1)
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
"   Examples:
"     call sj#ReplaceMotion('Va{', 'some text')
"     call sj#ReplaceMotion('V', 'replacement line')
"
" Note that the motion needs to include a visual mode key, like "V", "v" or
" "gv"
function! sj#ReplaceMotion(motion, text)
  " reset clipboard to avoid problems with 'unnamed' and 'autoselect'
  let saved_clipboard = &clipboard
  set clipboard=

  let saved_register_text = getreg('"', 1)
  let saved_register_type = getregtype('"')

  call setreg('"', a:text, 'v')
  exec 'silent normal! '.a:motion.'p'
  silent normal! gv=

  call setreg('"', saved_register_text, saved_register_type)
  let &clipboard = saved_clipboard
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
function! sj#ReplaceCols(start, end, text)
  let start_position = getpos('.')
  let end_position   = getpos('.')

  let start_position[2] = a:start
  let end_position[2]   = a:end

  return sj#ReplaceByPosition(start_position, end_position, a:text)
endfunction

" function! sj#ReplaceByPosition(start, end, text) {{{2
"
" Replace the area defined by the 'start' and 'end' positions with 'text'. The
" positions should be compatible with the results of getpos():
"
"   [bufnum, lnum, col, off]
"
function! sj#ReplaceByPosition(start, end, text)
  call setpos('.', a:start)
  call setpos("'z", a:end)

  return sj#ReplaceMotion('v`z', a:text)
endfunction

" Text retrieval {{{1
"
" These functions are similar to the text replacement functions, only retrieve
" the text instead.
"
" function! sj#GetMotion(motion) {{{2
"
" Execute the normal mode motion "motion" and return the text it marks.
"
" Note that the motion needs to include a visual mode key, like "V", "v" or
" "gv"
function! sj#GetMotion(motion)
  call sj#PushCursor()

  let saved_register_text = getreg('z', 1)
  let saved_register_type = getregtype('z')

  exec 'silent normal! '.a:motion.'"zy'
  let text = @z

  call setreg('z', saved_register_text, saved_register_type)
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

" function! sj#GetCols(start, end) {{{2
"
" Retrieve the text from columns "start" to "end" on the current line.
function! sj#GetCols(start, end)
  return strpart(getline('.'), a:start - 1, a:end - a:start + 1)
endfunction

" function! sj#GetByPosition(start, end) {{{2
"
" Fetch the area defined by the 'start' and 'end' positions. The positions
" should be compatible with the results of getpos():
"
"   [bufnum, lnum, col, off]
"
function! sj#GetByPosition(start, end)
  call setpos('.', a:start)
  call setpos("'z", a:end)

  return sj#GetMotion('v`z')
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

" Execute sj#Trim on each item of a List
function! sj#TrimList(list)
  return map(a:list, 'sj#Trim(v:val)')
endfunction

" Searching for patterns {{{1
"
" function! sj#SearchUnderCursor(pattern, flags, skip) {{{2
"
" Searches for a match for the given pattern under the cursor. Returns the
" result of the |search()| call if a match was found, 0 otherwise.
"
" Moves the cursor unless the 'n' flag is given.
"
" The a:flags parameter can include one of "e", "p", "s", "n", which work the
" same way as the built-in |search()| call. Any other flags will be ignored.
"
function! sj#SearchUnderCursor(pattern, ...)
  let [match_start, match_end] = call('sj#SearchposUnderCursor', [a:pattern] + a:000)
  if match_start > 0
    return match_start
  else
    return 0
  endif
endfunction

" function! sj#SearchposUnderCursor(pattern, flags, skip) {{{2
"
" Searches for a match for the given pattern under the cursor. Returns the
" start and (end + 1) column positions of the match. If nothing was found,
" returns [0, 0].
"
" Moves the cursor unless the 'n' flag is given.
"
" Respects the skip expression if it's given.
"
" See sj#SearchUnderCursor for the behaviour of a:flags
"
function! sj#SearchposUnderCursor(pattern, ...)
  if a:0 >= 1
    let given_flags = a:1
  else
    let given_flags = ''
  endif

  if a:0 >= 2
    let skip = a:2
  else
    let skip = ''
  endif

  let lnum        = line('.')
  let col         = col('.')
  let pattern     = a:pattern
  let extra_flags = ''

  " handle any extra flags provided by the user
  for char in ['e', 'p', 's']
    if stridx(given_flags, char) >= 0
      let extra_flags .= char
    endif
  endfor

  try
    call sj#PushCursor()

    " find the start of the pattern
    call search(pattern, 'bcW', lnum)
    let search_result = sj#SearchSkip(pattern, skip, 'cW'.extra_flags, lnum)
    if search_result <= 0
      return [0, 0]
    endif
    let match_start = col('.')

    " find the end of the pattern
    call sj#PushCursor()
    call sj#SearchSkip(pattern, skip, 'cWe', lnum)
    let match_end = col('.')

    " set the end of the pattern to the next character, or EOL. Extra logic
    " is for multibyte characters.
    normal! l
    if col('.') == match_end
      " no movement, we must be at the end
      let match_end = col('$')
    else
      let match_end = col('.')
    endif
    call sj#PopCursor()

    if !sj#ColBetween(col, match_start, match_end)
      " then the cursor is not in the pattern
      return [0, 0]
    else
      " a match has been found
      return [match_start, match_end]
    endif
  finally
    if stridx(given_flags, 'n') >= 0
      call sj#PopCursor()
    else
      call sj#DropCursor()
    endif
  endtry
endfunction

" function! sj#SearchSkip(pattern, skip, ...) {{{2
" A partial replacement to search() that consults a skip pattern when
" performing a search, just like searchpair().
"
" Note that it doesn't accept the "n" and "c" flags due to implementation
" difficulties.
function! sj#SearchSkip(pattern, skip, ...)
  " collect all of our arguments
  let pattern = a:pattern
  let skip    = a:skip

  if a:0 >= 1
    let flags = a:1
  else
    let flags = ''
  endif

  if stridx(flags, 'n') > -1
    echoerr "Doesn't work with 'n' flag, was given: ".flags
    return
  endif

  let stopline = (a:0 >= 2) ? a:2 : 0
  let timeout  = (a:0 >= 3) ? a:3 : 0

  " just delegate to search() directly if no skip expression was given
  if skip == ''
    return search(pattern, flags, stopline, timeout)
  endif

  " search for the pattern, skipping a match if necessary
  let skip_match = 1
  while skip_match
    let match = search(pattern, flags, stopline, timeout)

    " remove 'c' flag for any run after the first
    let flags = substitute(flags, 'c', '', 'g')

    if match && eval(skip)
      let skip_match = 1
    else
      let skip_match = 0
    endif
  endwhile

  return match
endfunction

function! sj#SkipSyntax(...)
  let syntax_groups = a:000
  let skip_pattern  = '\%('.join(syntax_groups, '\|').'\)'

  return "synIDattr(synID(line('.'),col('.'),1),'name') =~ '".skip_pattern."'"
endfunction

" Checks if the current position of the cursor is within the given limits.
"
function! sj#CursorBetween(start, end)
  return sj#ColBetween(col('.'), a:start, a:end)
endfunction

" Checks if the given column is within the given limits.
"
function! sj#ColBetween(col, start, end)
  return a:start <= a:col && a:end > a:col
endfunction

" Regex helpers {{{1
"
" function! sj#ExtractRx(expr, pat, sub) {{{2
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

" Compatibility {{{1
"
" Functionality that is present in newer versions of Vim, but needs a
" compatibility layer for older ones.
"
" function! sj#Keeppatterns(command) {{{2
"
" Executes the given command, but attempts to keep search patterns as they
" were.
"
function! sj#Keeppatterns(command)
  if exists(':keeppatterns')
    exe 'keeppatterns '.a:command
  else
    let histnr = histnr('search')

    exe a:command

    if histnr != histnr('search')
      call histdel('search', -1)
      let @/ = histget('search', -1)
    endif
  endif
endfunction

" Splitjoin-specific helpers {{{1

" These functions are not general-purpose, but can be used all around the
" plugin disregarding filetype, so they have no place in the specific autoload
" files.

function! sj#Align(from, to, type)
  if a:from >= a:to
    return
  endif

  if exists('g:tabular_loaded')
    call s:Tabularize(a:from, a:to, a:type)
  elseif exists('g:loaded_AlignPlugin')
    call s:Align(a:from, a:to, a:type)
  endif
endfunction

function! s:Tabularize(from, to, type)
  if a:type == 'hashrocket'
    let pattern = '^[^=>]*\zs=>'
  elseif a:type == 'css_declaration' || a:type == 'json_object'
    let pattern = '^[^:]*:\s*\zs\s/l0'
  elseif a:type == 'lua_table'
    let pattern = '^[^=]*\zs='
  elseif a:type == 'when_then'
    let pattern = 'then'
  else
    return
  endif

  exe a:from.",".a:to."Tabularize/".pattern
endfunction

function! s:Align(from, to, type)
  if a:type == 'hashrocket'
    let pattern = 'l: =>'
  elseif a:type == 'css_declaration' || a:type == 'json_object'
    let pattern = 'lp0W0 :\s*\zs'
  elseif a:type == 'when_then'
    let pattern = 'l: then'
  else
    return
  endif

  exe a:from.",".a:to."Align! ".pattern
endfunction

" Returns a pair with the column positions of the closest opening and closing
" braces on the current line. The a:open and a:close parameters are the
" opening and closing brace characters to look for.
"
" The optional parameters are the syntaxes to skip while searching.
"
" If a pair is not found on the line, returns [-1, -1]
"
" Examples:
"
"   let [start, end] = sj#LocateBracesOnLine('{', '}')
"   let [start, end] = sj#LocateBracesOnLine('{', '}', 'rubyString')
"   let [start, end] = sj#LocateBracesOnLine('[', ']')
"
function! sj#LocateBracesOnLine(open, close, ...)
  let [_bufnum, line, col, _off] = getpos('.')
  let search_pattern = '\V'.a:open.'\m.*\V'.a:close

  " bail early if there's obviously no match
  if getline('.') !~ search_pattern
    return [-1, -1]
  endif

  " optional skip parameter
  if a:0 > 0
    let skip = sj#SkipSyntax(a:1)
  else
    let skip = ''
  endif

  " try looking backwards, then forwards
  let found = searchpair('\V'.a:open, '', '\V'.a:close, 'cb', skip, line('.'))
  if found <= 0
    let found = sj#SearchSkip(search_pattern, skip, '', line('.'))
  endif

  if found > 0
    let from = col('.')
    normal! %
    let to = col('.')

    return [from, to]
  else
    return [-1, -1]
  endif
endfunction

" Removes all extra whitespace on the current line. Such is often left when
" joining lines that have been aligned.
"
"   Example:
"
"     var one = { one:   "two", three: "four" };
"     " turns into:
"     var one = { one: "two", three: "four" };
"
function! sj#CompressWhitespaceOnLine()
  call sj#PushCursor()

  s/\S\zs \+/ /g

  " Don't leave a history entry
  call histdel('search', -1)
  let @/ = histget('search', -1)

  call sj#PopCursor()
endfunction

" Parses a JSON-like object and returns a list of its components
" (comma-separated parts).
"
" Note that a:from and a:to are the start and end of the body, not the curly
" braces that usually define a JSON object. This makes it possible to use the
" function for parsing an argument list into separate arguments, knowing their
" start and end.
"
" Different languages have different rules for delimiters, so it might be a
" better idea to write a specific parser. See autoload/sj/argparser/js.vim for
" inspiration.
"
function! sj#ParseJsonObjectBody(from, to)
  " Just use js object parser
  let parser = sj#argparser#js#Construct(a:from, a:to, getline('.'))
  call parser.Process()
  return parser.args
endfunction
