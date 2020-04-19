require 'spec_helper'

describe "settings" do
  let(:filename) { 'test.rb' }

  before :each do
    vim.set 'expandtab'
    vim.set 'shiftwidth', 2
  end

  after :each do
    vim.command('unlet g:splitjoin_ruby_trailing_comma')
    vim.command('unlet g:splitjoin_disabled_split_callbacks')
  end

  specify "precedence" do
    set_file_contents <<~EOF
      foo = {one: 'two', three: 'four'}
    EOF

    vim.search('one')

    vim.command('let g:splitjoin_ruby_trailing_comma = 0')
    split

    assert_file_contents <<~EOF
      foo = {
        one: 'two',
        three: 'four'
      }
    EOF

    join
    vim.command('let g:splitjoin_ruby_trailing_comma = 1')
    split

    assert_file_contents <<~EOF
      foo = {
        one: 'two',
        three: 'four',
      }
    EOF

    join
    vim.command('let g:splitjoin_ruby_trailing_comma = 0')
    vim.command('let b:splitjoin_ruby_trailing_comma = 1')
    split

    assert_file_contents <<~EOF
      foo = {
        one: 'two',
        three: 'four',
      }
    EOF
  end

  specify "disabling callbacks" do
    set_file_contents <<~EOF
      foo = func(one, two) if bar?
    EOF

    vim.search 'one'
    split

    assert_file_contents <<~EOF
      if bar?
        foo = func(one, two)
      end
    EOF

    vim.command('let g:splitjoin_disabled_split_callbacks = ["sj#ruby#SplitIfClause"]')

    set_file_contents <<~EOF
      foo = func(one, two) if bar?
    EOF

    vim.search 'one'
    split

    assert_file_contents <<~EOF
      foo = func(one,
                 two) if bar?
    EOF
  end
end
