let b:splitjoin_split_callbacks = [
      \ 'sj#elixir#SplitDoBlock',
      \ 'sj#elixir#SplitArray',
      \ ]

let b:splitjoin_join_callbacks = [
      \ 'sj#elixir#JoinDoBlock',
      \ 'sj#elixir#JoinArray',
      \ 'sj#elixir#JoinCommaDelimitedItems',
      \ ]
