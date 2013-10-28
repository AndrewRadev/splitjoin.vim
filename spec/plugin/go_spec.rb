require 'spec_helper'

describe "go" do
  let(:filename) { 'test.go' }

  # Go is not built-in, so let's set it up manually
  def setup_go_filetype
    vim.set(:filetype, 'go')
    vim.set(:expandtab) # not canonical, but easier to test
    vim.set(:shiftwidth, 4)
  end

  specify "structs" do
    set_file_contents <<-EOF
      StructType{one: 1, two: "asdf", three: []int{1, 2, 3}}
    EOF
    setup_go_filetype

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
