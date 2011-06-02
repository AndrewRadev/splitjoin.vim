foo(bar, baz)
foo bar, baz

foo { bar(baz) }

foo(:one => 1, :two => 2)
foo :one => 1, :two => 2

foo :one, :two, :three => 3, :four => 4

foo :one, :two => :three do |something|
  something something
end
foo :one, :two => :three do
  something something
end

# nesting
foo :one => { :two => { :three => 3 }, :four => 4 }

# TODO: broken with multibyte characters on the line
foo :one, :two, { :three => 'ффяю', :four => 4 }
foo :one, :two, { :three => 3, :four => 4 }
foo :one, :three, { :three => 3, :four => 4 }

# strings
foo :one, :two => 'three, seven'
foo :one, :two, "three, four", :five => 'six, seven', :six => 7

# arrays
foo :one, :two => [3, 4], :five => [6, 7, 8]
foo :one, { :two => [3, 4], :five => [6, 7, 8] }

# hashes
{ :one => 1, :two => 2 }
foo = { :one => 1, :two => 2 }
{:one => 1, :two => 2}

# backticks
foo(:one, :two => `ls foo, bar`)

# items, grouped with round braces
foo :one, :two => (true || false || foo(bar, baz))
foo(:one, :two => (true || false || foo(bar, baz)))

foo :one, :two => /three, four/im, :five => :six
foo :one, :two => %|three, four|, :five => :six
foo :one, :two => %w|three, four|, :five => :six

foo? :one => 1, :two => 2
foo! :one => 1, :two => 2

Foo.bar :one => 1, :two => 2
Foo::bar :one => 1, :two => 2
