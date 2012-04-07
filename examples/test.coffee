(foo, bar) -> console.log foo
(foo, bar) ->
  console.log foo

do ->
  console.log bar if foo?
  if foo? then console.log bar

foo = { one: two, three: 'four' }

foo = "example"
foo = "example with #{interpolation}"
foo = "example with \"nested\" quotes"

# TODO (2012-04-07) Implement
foo = 'example with single quotes'
