(foo, bar) -> console.log foo

do ->
  console.log bar if foo?
  if foo? then console.log bar

foo = { one: two, three: 'four' }
