require 'spec_helper'

describe "go" do
  let(:filename) { 'test.go' }

  before :each do
    vim.set 'expandtab'
    vim.set 'shiftwidth', 4
  end

  specify "structs" do
    set_file_contents <<-EOF
      StructType{one: 1, two: "asdf", three: []int{1, 2, 3}}
    EOF

    split

    assert_file_contents <<-EOF
      StructType{
          one: 1,
          two: "asdf",
          three: []int{1, 2, 3},
      }
    EOF

    join

    assert_file_contents <<-EOF
      StructType{one: 1, two: "asdf", three: []int{1, 2, 3}}
    EOF
  end
end
