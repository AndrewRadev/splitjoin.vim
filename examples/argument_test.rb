foo(bar, baz)
foo bar, baz

foo { bar(baz) }

foo(:one => 1, :two => 2)
foo :one => 1, :two => 2

foo :one, :two, :three => 3, :four => 4

foo :one, :two, { :three => 'ффяю', :four => 4 }
foo :one, :two, { :three => 3, :four => 4 }
foo :one, :three, { :three => 3, :four => 4 }
foo :one, :two, { :three => 3, :four => 4 }

# strings
foo :one, :two => 'three, seven'
foo :one, :two, "three, four", :five => 'six, seven', :six => 7

# arrays
foo :one, :two => [3, 4], :five => [6, 7, 8]
# TODO parse hashes recursively
foo :one, { :two => [3, 4], :five => [6, 7, 8] }

# backticks
foo :one, :two => `ls foo, bar`

# items, grouped with round braces
foo :one, :two => (true || false || foo bar, baz)
# TODO nesting
foo :one, :two => (true || false || foo(bar, baz))
foo(:one, :two => (true || false || foo(bar, baz)))

# TODO more complex cases
