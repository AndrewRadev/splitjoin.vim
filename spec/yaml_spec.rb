require 'spec_helper'

describe "yaml" do
  let(:vim) { VIM }
  let(:filename) { 'test.yml' }

  before :each do
    vim.set 'expandtab'
    vim.set 'shiftwidth', 2
  end

  specify "arrays" do
    set_file_contents <<-EOF
      root:
        one: [1, 2]
        two: ['three', 'four']
    EOF

    vim.search 'one'
    split
    vim.search 'two'
    split

    assert_file_contents <<-EOF
      root:
        one:
          - 1
          - 2
        two:
          - 'three'
          - 'four'
    EOF

    vim.search 'one'
    join
    vim.search 'two'
    join

    assert_file_contents <<-EOF
      root:
        one: [1, 2]
        two: ['three', 'four']
    EOF
  end
end
