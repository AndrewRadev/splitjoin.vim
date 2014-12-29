require 'spec_helper'

describe "javascript" do
  let(:filename) { 'test.js' }

  before :each do
    vim.set(:expandtab)
    vim.set(:shiftwidth, 2)
  end

  specify "object literals" do
    set_file_contents "{ one: two, 'three': four }"

    vim.search '{'
    split

    assert_file_contents <<-EOF
      {
        one: two,
        'three': four
      }
    EOF

    join

    assert_file_contents "{one: two, 'three': four}"
  end

  specify "lists" do
    set_file_contents "[ 'one', 'two', 'three', 'four' ]"

    vim.search '['
    split

    assert_file_contents <<-EOF
      [
        'one',
        'two',
        'three',
        'four'
      ]
    EOF

    join

    assert_file_contents "['one', 'two', 'three', 'four']"
  end

  specify "functions" do
    set_file_contents "var foo = function() { return 'bar' };"

    vim.search 'function'
    split

    assert_file_contents <<-EOF
      var foo = function() {
        return 'bar'
      };
    EOF

    set_file_contents <<-EOF
      var foo = function() {
        one();
        two()
        return 'bar'
      };
    EOF

    join

    assert_file_contents "var foo = function() { one(); two(); return 'bar' };"
  end

  specify "named functions" do
    set_file_contents <<-EOF
      function example() {
        return 'bar'
      };
    EOF

    join

    assert_file_contents <<-EOF
      function example() { return 'bar' };
    EOF
  end

  specify "one-line ifs" do
    joined_if = "if (isTrue()) do();"
    split_if  = "if (isTrue()) {\n  do();\n}"

    set_file_contents(joined_if)
    split
    assert_file_contents(split_if)
    join
    assert_file_contents(joined_if)
  end
end
