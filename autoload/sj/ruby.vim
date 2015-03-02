function! sj#ruby#SplitIfClause()
  let line    = getline('.')
  let pattern = '\v(.*\S.*) (if|unless|while|until) (.*)'

  if line =~ pattern
    call sj#ReplaceMotion('V', substitute(line, pattern, '\2 \3\n\1\nend', ''))
    return 1
  else
    return 0
  endif
endfunction

function! sj#ruby#JoinIfClause()
  let line    = getline('.')
  let pattern = '\v^\s*(if|unless|while|until)'

  if line !~ pattern
    return 0
  endif

  let if_line_no = line('.')
  let else_line_pattern = '^'.repeat(' ', indent(if_line_no)).'else\s*\%(#.*\)\=$'
  let end_line_pattern = '^'.repeat(' ', indent(if_line_no)).'end\s*\%(#.*\)\=$'

  let else_line_no = search(else_line_pattern, 'W')
  call cursor(if_line_no, 1)
  let end_line_no = search(end_line_pattern, 'W')

  if end_line_no <= 0
    return 0
  endif

  if else_line_no && else_line_no < end_line_no
    return 0
  endif

  let [result, offset] = s:HandleComments(if_line_no, end_line_no)
  if !result
    return 1
  endif
  let if_line_no += offset
  let end_line_no += offset

  let lines = sj#GetLines(if_line_no, end_line_no)

  let if_line  = lines[0]
  let end_line = lines[-1]
  let body     = join(lines[1:-2], "\n")

  let if_line = sj#Trim(if_line)
  let body    = sj#Trim(body)
  let body    = s:JoinLines(body)

  let replacement = body.' '.if_line

  call sj#ReplaceLines(if_line_no, end_line_no, replacement)
  return 1
endfunction

function! sj#ruby#SplitTernaryClause()
  let line    = getline('.')
  let ternary_pattern = '\v(\w.*) \? (.*) : (.*)'
  let assignment_pattern = '\v^\s*\w* \= '

  if line =~ ternary_pattern
    let assignment = matchstr(line, assignment_pattern)

    if assignment != ''
      let line = substitute(line, assignment_pattern, '', '')
      let line = substitute(line, '(\(.*\))', '\1', '')

      call sj#ReplaceMotion('V', substitute(line, ternary_pattern,
            \ assignment.'if \1\n\2\nelse\n\3\nend', ''))
    else
      call sj#ReplaceMotion('V', substitute(line, ternary_pattern,
            \'if \1\n\2\nelse\n\3\nend', ''))
    endif

    return 1
  else
    return 0
  endif
endfunction

function! sj#ruby#JoinTernaryClause()
  let line    = getline('.')
  let pattern = '\v(if|unless) '

  if line =~ pattern
    let if_line_no = line('.')

    let else_line_no = if_line_no + 2
    let end_line_no  = if_line_no + 4

    let else_line = getline(else_line_no)
    let end_line  = getline(end_line_no)

    let clause_is_valid = 0

    " Three formats are allowed, all ifs can be replaced with unless
    "
    " if condition
    "   true
    " else
    "   false
    " end
    "
    " x = if condition    "     x = if condition
    "       true          "       true
    "     else            "     else
    "       false         "       false
    "     end             "     end
    "
    if else_line =~ '^\s*else\s*$' && end_line =~ '^\s*end\s*$'
      let if_column = match(line, pattern)
      let else_column = match(else_line, 'else')
      let end_column = match(end_line, 'end')
      let if_line_indent = indent(if_line_no)

      if else_column == end_column
        if (else_column == if_column) || (else_column == if_line_indent)
          let clause_is_valid = 1
        endif
      endif
    end

    if clause_is_valid
      let [result, offset] = s:HandleComments(if_line_no, end_line_no)
      if !result
        return 1
      endif
      let if_line_no   += offset
      let else_line_no += offset
      let end_line_no  += offset

      let upper_body = getline(if_line_no + 1)
      let lower_body = getline(else_line_no + 1)
      let upper_body = sj#Trim(upper_body)
      let lower_body = sj#Trim(lower_body)

      let assignment = matchstr(upper_body, '\v^.{-} \= ')

      if assignment != '' && lower_body =~ '^'.assignment
        let upper_body = substitute(upper_body, '^'.assignment, '', '')
        let lower_body = substitute(lower_body, '^'.assignment, '', '')
      else
        " clean the assignment var if it's invalid, so we don't have
        " to care about it later on
        let assignment = ''
      endif

      if line =~ 'if'
        let body = [upper_body, lower_body]
      else
        let body = [lower_body, upper_body]
      endif

      let body_str = join(body, " : ")
      let condition = substitute(line, pattern, '', '')
      let condition = substitute(condition, '\v^(\s*)', '\1'.assignment, '')

      let replacement = condition.' ? '.body_str

      if line =~ '\v\= (if|unless)' || assignment != ''
        let replacement = substitute(replacement, '\v(\= )(.*)', '\1(\2)', '')
      endif

      call sj#ReplaceLines(if_line_no, end_line_no, replacement)

      return 1
    endif
  endif

  return 0
endfunction

function! sj#ruby#JoinCase()
  let line_no = line('.')
  let line = getline('.')
  if line =~ '.*case'
    let end_line_pattern = '^'.repeat(' ', indent(line)).'end\s*$'
    let end_line_no = search(end_line_pattern, 'W')
    let lines = sj#GetLines(line_no + 1, end_line_no - 1)
    let counter = 1
    for body_line in lines
      call cursor(line_no + counter, 1)
      if ! call('sj#ruby#JoinWhenThen', [])
        let counter = counter + 1
      endif
    endfor

    " try to join else for extremely well formed cases and use
    " an alignment tool (optional)
    call cursor(line_no, 1)
    let new_end_line_no = search(end_line_pattern, 'W')
    let else_line_no = new_end_line_no - 2
    let else_line = getline(else_line_no)
    if else_line =~ '^'.repeat(' ', indent(line)).'else\s*$'
      let lines = sj#GetLines(line_no + 1, else_line_no - 1)
      if s:AllLinesStartWithWhen(lines)
        let next_line = getline(else_line_no + 1)
        let next_line = sj#Trim(next_line)
        let replacement = else_line.' '.next_line
        call sj#ReplaceLines(else_line_no, else_line_no + 1, replacement)
        if g:splitjoin_align
          call sj#Align(line_no + 1, else_line_no, 'when_then')
        endif
      endif
    endif

    " and check the new endline again for changes
    call cursor(line_no, 1)
    let new_end_line_no = search(end_line_pattern, 'W')

    if end_line_no > new_end_line_no
      return 1
    endif
  endif

  return 0
endfunction

function! s:AllLinesStartWithWhen(lines)
  for line in a:lines
    if line !~ '\s*when'
      return 0
    end
  endfor
  return 1
endfunction

function! sj#ruby#SplitCase()
  let line_no = line('.')
  let line = getline('.')
  if line =~ '.*case'
    let end_line_pattern = '^'.repeat(' ', indent(line)).'end\s*$'
    let end_line_no = search(end_line_pattern, 'W')
    let lines = sj#GetLines(line_no + 1, end_line_no - 1)
    let counter = 1
    for body_line in lines
      call cursor(line_no + counter, 1)
      if call('sj#ruby#SplitWhenThen', [])
        let counter = counter + 2
      else
        let counter = counter + 1
      endif
    endfor

    call cursor(line_no, 1)
    let new_end_line_no = search(end_line_pattern, 'W')
    let else_line_no = new_end_line_no - 1
    let else_line = getline(else_line_no)
    if else_line =~ '^'.repeat(' ', indent(line)).'else.*'
      call cursor(else_line_no, 1)
      call sj#ReplaceMotion('V', substitute(else_line, '\v^(\s*else) (.*)', '\1\n\2', ''))
      call cursor(else_line_no, 1)
      let new_end_line_no = search(end_line_pattern, 'W')
    endif

    if end_line_no > new_end_line_no
      return 1
    endif
  endif

  return 0
endfunction

function! sj#ruby#SplitWhenThen()
  let line = getline('.')
  let pattern = '\v(s*when.*) then (.*)'

  if line =~ pattern
    call sj#ReplaceMotion('V', substitute(line, pattern, '\1\n\2', ''))
    return 1
  else
    return 0
  endif
endfunction

function! sj#ruby#JoinWhenThen()
  let line = getline('.')

  if line =~ '^\s*when'
    let line_no = line('.')
    let one_down = getline(line_no + 1)
    let two_down = getline(line_no + 2)
    let pattern = '\v^\s*(when|else|end)'

    if one_down !~ pattern && two_down =~ pattern
      let one_down = sj#Trim(one_down)
      let replacement = line.' then '.one_down
      call sj#ReplaceLines(line_no, line_no + 1, replacement)
      return 1
    end
  end

  return 0
endfunction

function! sj#ruby#SplitProcShorthand()
  let pattern = '(&:\k\+[!?]\=)'

  if sj#SearchUnderCursor(pattern) <= 0
    return 0
  endif

  if search('(&:\zs\k\+[!?]\=)', '', line('.')) <= 0
    return 0
  endif

  let method_name = matchstr(sj#GetMotion('Vi('), '\k\+[!?]\=')
  let body = " do |i|\ni.".method_name."\nend"

  call sj#ReplaceMotion('Va(', body)
  return 1
endfunction

function! sj#ruby#SplitBlock()
  let pattern = '\v\{(\s*\|.{-}\|)?\s*(.{-})\s*\}'

  if sj#SearchUnderCursor('\v%(\k|!|\-\>|\?|\))\s*\zs'.pattern) <= 0
    return 0
  endif

  let start = col('.')
  normal! %
  let end = col('.')

  if start == end
    " the cursor hasn't moved, bail out
    return 0
  endif

  let body = sj#GetMotion('Va{')
  let multiline_block = 'do\1\n\2\nend'

  normal! %
  if search('\S\%#', 'Wbn')
    let multiline_block = ' '.multiline_block
  endif

  let body = join(split(body, '\s*;\s*'), "\n")
  let replacement = substitute(body, '^'.pattern.'$', multiline_block, '')

  call sj#ReplaceMotion('Va{', replacement)

  return 1
endfunction

function! sj#ruby#JoinBlock()
  let do_pattern = '\<do\>\(\s*|.*|\s*\)\?$'

  let do_line_no = search(do_pattern, 'cW', line('.'))
  if do_line_no <= 0
    let do_line_no = search(do_pattern, 'bcW', line('.'))
  endif

  if do_line_no <= 0
    return 0
  endif

  let end_line_no = searchpair(do_pattern, '', '\<end\>', 'W')

  let [result, offset] = s:HandleComments(do_line_no, end_line_no)
  if !result
    return 1
  endif
  let do_line_no += offset
  let end_line_no += offset

  let lines = sj#GetLines(do_line_no, end_line_no)
  let lines = sj#TrimList(lines)

  let do_line  = substitute(lines[0], do_pattern, '{\1', '')
  let body     = join(lines[1:-2], '; ')
  let body     = sj#Trim(body)
  let end_line = substitute(lines[-1], 'end', '}', '')

  let replacement = do_line.' '.body.' '.end_line

  " shorthand to_proc if possible
  let replacement = substitute(replacement, '\s*{ |\(\k\+\)| \1\.\(\k\+[!?]\=\) }$', '(\&:\2)', '')

  call sj#ReplaceLines(do_line_no, end_line_no, replacement)

  return 1
endfunction

function! sj#ruby#SplitCachingConstruct()
  let line = getline('.')

  if line =~ '||=' && line !~ '||=\s\+begin\>'
    let replacement = substitute(line, '||=\s\+\(.*\)$', '||= begin\n\1\nend', '')
    call sj#ReplaceMotion('V', replacement)

    return 1
  else
    return 0
  endif
endfunction

function! sj#ruby#JoinCachingConstruct()
  let begin_line = getline('.')
  let body_line  = getline(line('.') + 1)
  let end_line   = getline(line('.') + 2)

  if begin_line =~ '||=\s\+begin' && end_line =~ '^\s*end'
    let lvalue      = substitute(begin_line, '\s\+||=\s\+begin.*$', '', '')
    let body        = sj#Trim(body_line)
    let replacement = lvalue.' ||= '.body

    call sj#ReplaceLines(line('.'), line('.') + 2, replacement)

    return 1
  else
    return 0
  endif
endfunction

function! sj#ruby#JoinHash()
  let line = getline('.')

  if line =~ '{\s*$'
    return s:JoinHashWithCurlyBraces()
  elseif line =~ '(\s*$'
    return s:JoinHashWithRoundBraces()
  elseif line =~ ',\s*$'
    return s:JoinHashWithoutBraces()
  else
    return 0
  endif
endfunction

function! sj#ruby#SplitOptions()
  " Variables:
  "
  " option_type:   ['option', 'hash']
  " function_type: ['with_spaces', 'with_round_braces']
  "

  call sj#PushCursor()
  let [from, to] = sj#argparser#ruby#LocateHash()
  call sj#PopCursor()

  if from < 0 || !sj#CursorBetween(from, to)
    call sj#PushCursor()
    let [from, to, function_type] = sj#argparser#ruby#LocateFunction()
    call sj#PopCursor()

    let option_type = 'option'
  else
    let option_type = 'hash'
  endif

  if from < 0
    return 0
  endif

  " with options, we may not know the end, but we do know the start
  if option_type == 'option' && to < 0 && !sj#CursorBetween(from, col('$'))
    return 0
  endif

  " if we know both start and end, but the cursor is not there, bail out
  if option_type == 'option' && to >= 0 && !sj#CursorBetween(from, to)
    return 0
  endif

  let [from, to, args, opts, hash_type] = sj#argparser#ruby#ParseArguments(from, to, getline('.'))

  if len(opts) < 1 && len(args) > 0 && option_type == 'option'
    " no options found, but there are arguments, split those
    let replacement = join(args, ",\n")

    if !g:splitjoin_ruby_hanging_args
      let replacement = "\n".replacement."\n"
    elseif len(args) == 1
      " if there's only one argument, there's nothing to do in the "hanging"
      " case
      return 0
    endif

    if function_type == 'with_spaces'
      let replacement = "(".replacement.")"
      let from -= 1 " Also replace the space before the argument list
    endif

    call sj#ReplaceCols(from, to, replacement)
    return 1
  endif

  let replacement = ''
  let alignment_start = line('.')

  " first, prepare the already-existing arguments
  if len(args) > 0
    let replacement .= join(args, ', ') . ','
  endif

  " add opening brace
  if g:splitjoin_ruby_curly_braces

    if option_type == 'hash'
      " Example: one = {:two => 'three'}
      "
      let replacement .= "{\n"
      let alignment_start += 1
    elseif function_type == 'with_round_braces' && len(args) > 0
      " Example: create(:inquiry, :state => state)
      "
      let replacement .= " {\n"
      let alignment_start += 1
    elseif function_type == 'with_round_braces' && len(args) == 0
      " Example: create(one: 'two', three: 'four')
      "
      let replacement .= "{\n"
      let alignment_start += 1
    else
      " add braces in all other cases
      let replacement .= " {\n"
      let alignment_start += 1
    endif

  else " !g:splitjoin_ruby_curly_braces

    if option_type == 'option' && function_type == 'with_round_braces' && len(args) > 0
      " Example: User.new(:one, :two => 'three')
      "
      let replacement .= "\n"
      let alignment_start += 1
    elseif option_type == 'option' && function_type == 'with_spaces' && len(args) > 0
      " Example: User.new :one, :two => 'three'
      "
      let replacement .= "\n"
      let alignment_start += 1
    elseif option_type == 'option' && function_type == 'with_round_braces' && len(args) == 0
      " Example: User.new(:two => 'three')
      "
      " no need to add anything
    endif

  endif

  " add options
  let replacement .= join(opts, ",\n")

  " add closing brace
  if !g:splitjoin_ruby_curly_braces && option_type == 'option' && function_type == 'with_round_braces'
    " no need to add anything
  elseif g:splitjoin_ruby_curly_braces || option_type == 'hash' || len(args) == 0
    if g:splitjoin_ruby_trailing_comma
      let replacement .= ','
    endif

    let replacement .= "\n}"
  endif

  call sj#ReplaceCols(from, to, replacement)

  if g:splitjoin_align && hash_type != 'mixed'
    let alignment_end = alignment_start + len(opts) - 1

    if hash_type == 'classic'
      call sj#Align(alignment_start, alignment_end, 'hashrocket')
    elseif hash_type == 'new'
      call sj#Align(alignment_start, alignment_end, 'json_object')
    endif
  endif

  return 1
endfunction

function! sj#ruby#JoinContinuedMethodCall()
  if getline('.') !~ '\.$'
    return 0
  endif

  let start_lineno = line('.')
  silent! normal! zO
  normal! j

  while line('.') < line('$') && getline('.') =~ '\.$'
    normal! j
  endwhile

  let end_lineno = line('.') - 1

  exe start_lineno.','.end_lineno.'s/\n\_s*//'
endfunction

function! sj#ruby#JoinHeredoc()
  let heredoc_pattern = '<<-\?\([^ \t,]\+\)'

  if sj#SearchUnderCursor(heredoc_pattern) <= 0
    return 0
  endif

  let start_lineno      = line('.')
  let remainder_of_line = sj#GetCols(col('.'), col('$'))
  let delimiter         = sj#ExtractRx(remainder_of_line, heredoc_pattern, '\1')

  " we won't be needing the rest of the line
  normal! "_D

  if search('^\s*'.delimiter.'\s*$', 'W') <= 0
    return 0
  endif

  let end_lineno = line('.')

  if end_lineno - start_lineno > 1
    let lines = sj#GetLines(start_lineno + 1, end_lineno - 1)
    let lines = sj#TrimList(lines)
    let body  = join(lines, " ")
  else
    let body = ''
  endif

  if body =~ '\%(#{\|''\)'
    let quoted_body = '"'.escape(escape(body, '"'), '\').'"'
  else
    let quoted_body = "'".body."'"
  endif

  let replacement = getline(start_lineno).substitute(remainder_of_line, heredoc_pattern, quoted_body, '')
  call sj#ReplaceLines(start_lineno, end_lineno, replacement)
  undojoin " with the 'normal! D'

  return 1
endfunction

function! sj#ruby#SplitString()
  let string_pattern       = '\(\%(^\|[^\\]\)\zs\([''"]\)\).\{-}[^\\]\+\2'
  let empty_string_pattern = '\%(''''\|""\)'

  let [match_start, match_end] = sj#SearchposUnderCursor(string_pattern)
  if match_start <= 0
    let [match_start, match_end] = sj#SearchposUnderCursor(empty_string_pattern)
    if match_start <= 0
      return 0
    endif
  endif

  let string    = sj#GetCols(match_start, match_end - 1)
  let delimiter = string[0]

  if match_end - match_start > 2
    let string_body = sj#GetCols(match_start + 1, match_end - 2)."\n"
  else
    let string_body = ''
  endif

  if delimiter == '"'
    let string_body = substitute(string_body, '\\"', '"', 'g')
  elseif delimiter == "'"
    let string_body = substitute(string_body, "\\''", "'", 'g')
  endif

  if g:splitjoin_ruby_heredoc_type == '<<-'
    call sj#ReplaceCols(match_start, match_end - 1, '<<-EOF')
    let replacement = getline('.')."\n".string_body."EOF"
    call sj#ReplaceMotion('V', replacement)
  elseif g:splitjoin_ruby_heredoc_type == '<<'
    call sj#ReplaceCols(match_start, match_end - 1, '<<EOF')
    let replacement = getline('.')."\n".string_body."EOF"
    call sj#ReplaceMotion('V', replacement)
    exe (line('.') + 1).','.(line('.') + 2).'s/^\s*//'
  else
    throw 'Unknown value for g:splitjoin_ruby_heredoc_type, "'.g:splitjoin_ruby_heredoc_type.'"'
  endif

  return 1
endfunction

function! sj#ruby#SplitArrayLiteral()
  if synIDattr(synID(line('.'), col('.'), 1), "name") !~ 'rubyString\%(Delimiter\)\='
    return 0
  endif

  let lineno = line('.')
  let indent = indent('.')

  if search('%[wiWI]', 'Wbce', line('.')) <= 0 &&
        \ search('%[wiWI]', 'Wce', line('.')) <= 0
    return 0
  endif

  if col('.') == col('$')
    " we're at the end of the line, bail out
    return 0
  endif

  normal! l
  let opening_bracket = getline('.')[col('.') - 1]

  if col('.') == col('$')
    " we're at the end of the line, bail out
    return 0
  endif
  normal! l

  let closing_bracket = s:ArrayLiteralClosingBracket(opening_bracket)

  let array_pattern = '\%(\k\|\s\)*\ze\V'.closing_bracket
  let [start_col, end_col] = sj#SearchposUnderCursor(array_pattern)
  if start_col <= 0
    return 0
  endif

  if start_col == end_col - 1
    " just insert a newline, nothing inside the list
    exe "normal! i\<cr>"
    call sj#SetIndent(end_col, indent)
    return 1
  endif

  let array_body = sj#GetCols(start_col, end_col - 1)
  let array_items = split(array_body, '\s\+')
  call sj#ReplaceCols(start_col, end_col - 1, "\n".join(array_items, "\n")."\n")

  call sj#SetIndent(lineno + 1, lineno + len(array_items), indent + &sw)
  call sj#SetIndent(lineno + len(array_items) + 1, indent)

  return 0
endfunction

function! sj#ruby#JoinArrayLiteral()
  if synIDattr(synID(line('.'), col('.'), 1), "name") != 'rubyStringDelimiter'
    return 0
  endif

  if search('%[wiWI].$', 'Wce', line('.')) <= 0
    return 0
  endif

  let opening_bracket = getline('.')[col('.') - 1]
  let closing_bracket = s:ArrayLiteralClosingBracket(opening_bracket)

  let start_lineno = line('.')
  let end_lineno   = start_lineno + 1
  let end_pattern  = '^\s*\V'.closing_bracket.'\m\s*$'
  let word_pattern =  '^\%(\k\|\s\)*$'

  while end_lineno <= line('$') && getline(end_lineno) !~ end_pattern
    if getline(end_lineno) !~ word_pattern
      return 0
    endif
    let end_lineno += 1
  endwhile

  if getline(end_lineno) !~ end_pattern
    return 0
  endif

  if end_lineno - start_lineno < 1
    " nothing to join, bail out
    return 0
  endif

  if end_lineno - start_lineno == 1
    call sj#Keeppatterns('s/\n\_s*//')
    return 1
  endif

  let words = sj#TrimList(sj#GetLines(start_lineno + 1, end_lineno - 1))
  call sj#ReplaceLines(start_lineno + 1, end_lineno, join(words, ' ').closing_bracket)
  exe start_lineno
  call sj#Keeppatterns('s/\n\_s*//')

  return 1
endfunction

" Helper functions

function! s:JoinHashWithCurlyBraces()
  normal! $

  let original_body = sj#GetMotion('Vi{')
  let body = original_body

  if g:splitjoin_normalize_whitespace
    let body = substitute(body, '\s\+=>\s\+', ' => ', 'g')
    let body = substitute(body, '\s\+\k\+\zs:\s\+', ': ', 'g')
  endif

  " remove trailing comma
  let body = substitute(body, ',\ze\_s*$', '', '')

  if body != original_body
    call sj#ReplaceMotion('Vi{', body)
  endif

  normal! Va{J

  return 1
endfunction

function! s:JoinHashWithRoundBraces()
  normal! $

  let body = sj#GetMotion('Vi(',)
  if g:splitjoin_normalize_whitespace
    let body = substitute(body, '\s*=>\s*', ' => ', 'g')
  endif

  " remove trailing comma
  let body = substitute(body, ',\ze\_s*$', '', '')

  let body = join(sj#TrimList(split(body, "\n")), ' ')
  call sj#ReplaceMotion('Va(', '('.body.')')

  return 1
endfunction

function! s:JoinHashWithoutBraces()
  let start_lineno = line('.')
  let end_lineno   = start_lineno
  let lineno       = nextnonblank(start_lineno + 1)
  let line         = getline(lineno)
  let indent       = repeat(' ', indent(lineno))

  while lineno <= line('$') && ((line =~ '^'.indent && line =~ '=>') || line =~ '^\s*)')
    let end_lineno = lineno
    let lineno     = nextnonblank(lineno + 1)
    let line       = getline(lineno)
  endwhile

  call cursor(start_lineno, 0)
  exe "normal! V".(end_lineno - start_lineno)."jJ"
endfunction

function! s:JoinLines(text)
  let lines = sj#TrimList(split(a:text, "\n"))

  if len(lines) > 1
    return '('.join(lines, '; ').')'
  else
    return join(lines, '; ')
  endif
endfunction

function! s:HandleComments(start_line_no, end_line_no)
  let start_line_no = a:start_line_no
  let end_line_no   = a:end_line_no

  let [success, failure] = [1, 0]
  let offset = 0

  let comments = s:FindComments(start_line_no, end_line_no)

  if len(comments) > 1
    echomsg "Splitjoin: Can't join this due to the inline comments. Please remove them first."
    return [failure, 0]
  endif

  if len(comments) == 1
    let [start_line_no, end_line_no] = s:MigrateComments(comments, a:start_line_no, a:end_line_no)
    let offset = start_line_no - a:start_line_no
  else
    let offset = 0
  endif

  return [success, offset]
endfunction

function! s:FindComments(start_line_no, end_line_no)
  call sj#PushCursor()

  let comments = []

  for lineno in range(a:start_line_no, a:end_line_no)
    exe lineno
    normal! 0

    while search('\s*#.*$', 'W', lineno) > 0
      let col = col('.')

      normal! f#
      if synIDattr(synID(lineno, col('.'), 1), "name") == 'rubyComment'
        let comment = sj#GetCols(col, col('$'))
        call add(comments, [lineno, col, comment])
        break
      endif
    endwhile
  endfor

  call sj#PopCursor()

  return comments
endfunction

function! s:MigrateComments(comments, start_line_no, end_line_no)
  call sj#PushCursor()

  let start_line_no = a:start_line_no
  let end_line_no   = a:end_line_no

  for [line, col, _c] in a:comments
    call cursor(line, col)
    normal! "_D
  endfor

  for [_l, _c, comment] in a:comments
    call append(start_line_no - 1, comment)

    exe start_line_no
    normal! ==

    let start_line_no = start_line_no + 1
    let end_line_no   = end_line_no + 1
  endfor

  call sj#PopCursor()

  return [start_line_no, end_line_no]
endfunction

function! s:ArrayLiteralClosingBracket(opening_bracket)
  let opening_bracket = a:opening_bracket

  if opening_bracket == '{'
    let closing_bracket = '}'
  elseif opening_bracket == '('
    let closing_bracket = ')'
  elseif opening_bracket == '<'
    let closing_bracket = '>'
  elseif opening_bracket == '['
    let closing_bracket = ']'
  else
    let closing_bracket = opening_bracket
  endif

  return closing_bracket
endfunction
