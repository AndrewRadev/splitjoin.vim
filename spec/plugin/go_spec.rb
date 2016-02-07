require 'spec_helper'

describe "go" do
  let(:filename) { 'test.go' }

  # Go is not built-in, so let's set it up manually
  def setup_go_filetype
    vim.set(:filetype, 'go')
  end

  specify "imports" do
    set_file_contents <<-EOF
      import "fmt"
    EOF
    setup_go_filetype

    vim.search('import')
    split

    # In case there is no Go installed, deindent everything:
    vim.normal '3<<3<<'
    vim.write

    assert_file_contents <<-EOF
    import (
    "fmt"
    )
    EOF

    vim.search('import')
    join

    assert_file_contents <<-EOF
      import "fmt"
    EOF
  end

  specify "var/const modifiers" do
    set_file_contents <<-EOF
      var foo string
      const bar string
    EOF
    setup_go_filetype

    vim.search('var')
    split
    vim.search('const')
    split

    # In case there is no Go installed, deindent everything:
    vim.normal 'gg6<<6<<'
    vim.write

    assert_file_contents <<-EOF
    var (
    foo string
    )
    const (
    bar string
    )
    EOF

    vim.search('var')
    join
    vim.search('const')
    join

    assert_file_contents <<-EOF
      var foo string
      const bar string
    EOF
  end

  specify "structs" do
    set_file_contents <<-EOF
      StructType{one: 1, two: "asdf", three: []int{1, 2, 3}}
    EOF
    setup_go_filetype

    split

    # In case there is no Go installed, deindent everything:
    vim.normal '5<<5<<5<<5<<'
    vim.write

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
