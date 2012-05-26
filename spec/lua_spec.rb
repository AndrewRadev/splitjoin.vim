require 'spec_helper'

describe "lua" do
  let(:vim) { VIM }
  let(:filename) { 'test.lua' }

  before :each do
    vim.set 'expandtab'
    vim.set 'shiftwidth', 2
  end

  specify "functions" do
    set_file_contents <<-EOF
      function example () print("foo"); print("bar") end
    EOF

    split

    assert_file_contents <<-EOF
      function example ()
        print("foo"); print("bar")
      end
    EOF

    join

    assert_file_contents <<-EOF
      function example () print("foo"); print("bar") end
    EOF
  end

  specify "lambda functions" do
    set_file_contents <<-EOF
      local something = other(function (one, two) print("foo") end)
    EOF

    split

    assert_file_contents <<-EOF
      local something = other(function (one, two)
        print("foo")
      end)
    EOF

    join

    assert_file_contents <<-EOF
      local something = other(function (one, two) print("foo") end)
    EOF
  end
end
