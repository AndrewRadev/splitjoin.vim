let example_one = {
      \ 'one': 'two',
      \ 'three': 'four'
      \ }

let example_two = [
      \ 'one',
      \ 'two'
      \ ]

command! Foo if one |
      \   'two'     |
      \ else        |
      \   'three'   |
      \ endif
