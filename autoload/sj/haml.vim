" TODO (2013-05-09) Only works for very simple things, needs work
function! sj#haml#SplitInterpolation()
  let lineno  = line('.')
  let line    = getline('.')
  let indent  = indent('.')
  let pattern = '^\s*%.\{-}\zs='

  if line !~ pattern
    return 0
  endif

  exe 's/'.pattern.'/\r=/'
  call s:SetIndent(lineno + 1, lineno + 1, indent + &sw)

  return 1
endfunction

function! sj#haml#JoinInterpolation()
  if line('.') == line('$')
    return 0
  endif

  let line      = getline('.')
  let next_line = getline(line('.') + 1)

  if !(line =~ '^\s*%\k\+\s*$' && next_line =~ '^\s*=')
    return 0
  end

  s/\n\s*//
  return 1
endfunction

" Sets the absolute indent of the given range of lines to the given indent
function! s:SetIndent(from, to, indent)
  let new_whitespace = repeat(' ', a:indent)
  exe a:from.','.a:to.'s/^\s*/'.new_whitespace
endfunction
