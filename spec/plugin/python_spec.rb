require 'spec_helper'

describe "python" do
  let(:filename) { 'test.py' }

  before :each do
    vim.set(:expandtab)
    vim.set(:shiftwidth, 4)
  end

  specify "dictionaries" do
    set_file_contents "spam = {'spam': [1, 2, 3], 'spam, spam': 'eggs'}"

    vim.search '{'
    split

    assert_file_contents <<-EOF
      spam = {
              'spam': [1, 2, 3],
              'spam, spam': 'eggs'
              }
    EOF

    join

    assert_file_contents "spam = {'spam': [1, 2, 3], 'spam, spam': 'eggs'}"
  end

  specify "dictionaries with non-string keys" do
    set_file_contents "spam = {spam: [1, 2, 3], 'spam, spam': 'eggs'}"

    vim.search '{'
    split

    assert_file_contents <<-EOF
      spam = {
              spam: [1, 2, 3],
              'spam, spam': 'eggs'
              }
    EOF

    join

    assert_file_contents "spam = {spam: [1, 2, 3], 'spam, spam': 'eggs'}"
  end

  specify "lists" do
    set_file_contents 'spam = [1, [2, 3], 4]'

    vim.search '[1'
    split

    assert_file_contents <<-EOF
      spam = [1,
              [2, 3],
              4]
    EOF

    join

    assert_file_contents 'spam = [1, [2, 3], 4]'
  end

  specify "imports" do
    set_file_contents 'from foo import bar, baz'

    split

    assert_file_contents <<-EOF
      from foo import bar,\\
              baz
    EOF

    join

    assert_file_contents 'from foo import bar, baz'
  end

  specify "statements" do
    set_file_contents 'while True: loop()'

    split

    assert_file_contents <<-EOF
      while True:
          loop()
    EOF

    join

    assert_file_contents 'while True: loop()'
  end

  specify "splitting within a string" do
    set_file_contents <<-EOF
      run("one", "two", "three {}".format(four))
    EOF

    vim.search('one')
    split

    assert_file_contents <<-EOF
      run("one",
      "two",
      "three {}".format(four))
    EOF
  end

  specify "chained method calls" do
    set_file_contents <<-EOF
      SomeModel.objects.filter(asdf=1, qwer=2).exclude(zxcv=2, tyui=3)
    EOF

    vim.search('zxcv')
    split

    assert_file_contents <<-EOF
      SomeModel.objects.filter(asdf=1, qwer=2).exclude(zxcv=2,
              tyui=3)
    EOF
  end
end
