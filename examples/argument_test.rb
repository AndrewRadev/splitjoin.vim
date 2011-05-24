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

# TODO more complex cases
