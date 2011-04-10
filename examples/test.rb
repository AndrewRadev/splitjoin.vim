# hashes

{ :one => 'two', 'two three' => 'four', 5 => 'six', "bla bla" => "bla" }

foo = { :bar => 'baz', :one => 'two' }
{ :bar => 'baz', :one => 'two' }
foo = { :bar => 'baz', :one => { :two => 'three', :four => 'five' }, :five => 'six' }
mail({ :to => 'me', :from => 'me' })
{ :bar => 'baz', :one => 'two' }.merge(:one => 42)

{
  :one => { :two => :three },
  'one two' => { :two => :three },
  "one two" => { :two => :three },
  :'one two' => { :two => :three },
  :"one two" => { :two => :three }
}

# option hashes:

foo 1, 2, :one => 1, :two => 2, :three => 'three'
class Bar
  foo 1, 2, :one => 1, :two => 2, :three => 'three'
end
foo 1, 2, :one => 1, :two => 2, :three => 'three' do
  something
end
foo 1, 2, :one => 1, :two => 2, :three => 'three' { |bar| something(bar) }
foo 1, 2, :one => 1, :two => 2, :three => 'three' do |bar|
  something(bar)
end

# TODO: no-bracket options with nested hashes
foo 1, 2, :bar => 'baz', :one => { :two => 'three', :foo => { 'bar' => 'baz' }, :four => 'five' }, :five => 'six'
foo 1, 2, :bar => 'baz', :one => { :two => 'three', :foo => { 'bar' => 'baz' }, :four => 'five' }
foo 1, 2, :bar => 'baz', :one => { :two => 'three', :foo => { 'bar' => 'baz' }, :four => 'five' } { |one| two }

# option hashes with a single item

root :to => 'articles#index'

redirect_to root_path, :error => 'ф'
redirect_to root_path, :error => 'こ'
redirect_to root_path, :error => 'f'

# multiple hashes in parameter list

foo 1, 2, { :bar => :baz }, :baz => :qux
foo 1, 2, { :bar => :baz }, { :baz => :qux }

# blocks

Bar.new { |b| puts b.to_s; puts 'foo' }
Bar.new { puts self.to_s }

class Baz
  def qux
    # if/unless/while/until:

    return if problem?
    return 42 unless something_wrong?
    foo 1, 2, :one => 1, :two => 2, :three => 'three' if condition?
    foo = "bar" if one.two?
    n += 1 while n < 10
    n += 1 until n > 10

    # multiline if/unless

    if one and two
      three
      four
    end
  end
end
