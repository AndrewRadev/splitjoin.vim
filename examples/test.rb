# encoding: utf-8

# hashes

{ :one => 'two', 'two three' => 'four', 5 => 'six', "bla bla" => "bla" }

foo = { :bar => '', :one => 'two' }
{ :bar => 'baz', :one => 'two' }
foo = { :bar => { :bazbar => 1 }, :one => { :two => 'three', :four => 'five' }, :five => 'six' }
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
foo 1, 2, :one => 1, :two => 2, :three => 'three' do |bar|
  something(bar)
end

# 1.9 hashes:

{ one: 'two', two: 'three' }

foo = { bar: 'baz', one_two: 3  }
foo = { bar: 'baz', 'one' => 2  }

foo 1, 2, one: 1, :two => 2, three: 'three'

redirect_to root_path, :error => 'ф'
redirect_to root_path, :error => 'こ'
redirect_to root_path, :error => 'f'

mail(:to => 'me', :from => 'me')
mail :to => t('me'), :from => 'me'

foo 1, 2, :bar => 'baz', :one => { :two => 'three', :foo => { 'bar' => 'baz' }, :four => 'five' }, :five => 'six'
foo 1, 2, :bar => 'baz', :one => { :two => 'three', :foo => { 'bar' => 'baz' }, :four => 'five' }
foo 1, 2, :bar => 'baz', :one => { :two => 'three', :foo => { 'bar' => 'baz' }, :four => 'five' } do |one|
  two
end

one << two(:three => :four)
three = one + two(:three => :four)
three = one - two(:three => :four)
three = one / two(:three => :four)
three = one * two(:three => :four)
three = one ^ two(:three => :four)
three = one % two(:three => :four)

# hashes with extra whitespace

one = {
  :one   => 'two',
  :three => 'four',
  :a     => 'b'
}

# option hashes with a single item

root :to => 'articles#index'

# multiple hashes in parameter list

foo 1, 2, { :bar => :baz }, :baz => :qux
foo 1, 2, { :bar => :baz }, { :baz => :qux }

# joining options without curly braces

User.new(
  :first_name => "Andrew",
  :last_name => "Radev"
)
User.new :one, :first_name => "Andrew", :last_name => "Radev"
User.new(:one, :first_name => "Andrew", :last_name => "Radev")

# caching constructs

@two ||= 1 + 1
# other splitting takes precedence
@two ||= lambda { |one| one.two }
@two ||= two(:three => :four, :five => :six)

# blocks

Bar.new { |b| puts b.to_s; puts 'foo' }
Bar.new { puts self.to_s }
Bar.new { foo({ :one => :two, :three => :four }) }
Bar.new { |one| one.new { |two| two.three } }
foo(items.map do |i|
  i.bar
end) # comment

foo 'line with do in it' do |something|
  something
end

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
