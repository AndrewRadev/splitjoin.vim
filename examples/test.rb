# hashes

foo = { :bar => 'baz', :one => 'two' }
{ :bar => 'baz', :one => 'two' }
foo = { :bar => 'baz', :one => { :two => 'three', :four => 'five' }, :five => 'six' }
mail({ :to => 'me', :from => 'me' })
{ :bar => 'baz', :one => 'two' }.merge(:one => 42)

# TODO: option hashes:

foo 1, 2, :one => 1, :two => 2, :three => 'three'
class Bar
  foo 1, 2, :one => 1, :two => 2, :three => 'three'
end

# blocks

Bar.new { |b| puts b.to_s; puts 'foo' }
Bar.new { puts self.to_s }

class Baz
  def qux
    # if/unless:

    return if problem?
    return 42 unless something_wrong?
    foo 1, 2, :one => 1, :two => 2, :three => 'three' if condition?
    foo = "bar" if one.two?

    # multiline if/unless

    if one and two
      three
      four
    end
  end
end
