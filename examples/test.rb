# hashes and option hashes:

foo 1, 2, :one => 1, :two => 2, :three => 'three'

foo = { :bar => 'baz', :one => 'two' }

class Bar
  foo 1, 2, :one => 1, :two => 2, :three => 'three'
end

# blocks:

Bar.new { |b| puts b.to_s; puts 'foo' }

Bar.new { puts self.to_s }

class Baz
  def qux
    # if/unless:
    return if problem?

    return 42 unless something_wrong?

    foo 1, 2, :one => 1, :two => 2, :three => 'three' if condition?

    foo = "bar" if one.two?
  end
end
