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
      type ChanDir int
    EOF
    setup_go_filetype

    vim.search('var')
    split
    vim.search('const')
    split
    vim.search('type')
    split

    # In case there is no Go installed, deindent everything:
    vim.normal 'gg9<<9<<'
    vim.write

    assert_file_contents <<-EOF
    var (
    foo string
    )
    const (
    bar string
    )
    type (
    ChanDir int
    )
    EOF

    vim.search('var')
    join
    vim.search('const')
    join
    vim.search('type')
    join

    assert_file_contents <<-EOF
      var foo string
      const bar string
      type ChanDir int
    EOF
  end

  specify "structs" do
    set_file_contents <<-EOF
      StructType{one: 1, two: "asdf", three: []int{1, 2, 3}}
    EOF
    setup_go_filetype

    vim.search 'one:'
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

  describe "funcs" do
    def assert_split_join(initial, split_expected, join_expected)
      set_file_contents initial
      setup_go_filetype
      split
      # In case there is no Go installed, deindent everything:
      vim.normal '9<<9<<9<<9<<'
      vim.write
      assert_file_contents split_expected
      join
      assert_file_contents join_expected
    end

    it "handles function definitions" do
      initial = <<-EOF
        func Func(a, b int, c time.Time, d func(int) error, e func(int, int) (int, error), f ...time.Time) {
        }
      EOF
      split = <<-EOF
        func Func(
        a, b int,
        c time.Time,
        d func(int) error,
        e func(int, int) (int, error),
        f ...time.Time,
        ) {
        }
      EOF
      joined = <<-EOF
        func Func(a, b int, c time.Time, d func(int) error, e func(int, int) (int, error), f ...time.Time) {
        }
      EOF
      assert_split_join(initial, split, joined)
    end

    it "handles function definitions with return types" do
      initial = <<-EOF
        func Func(a, b int, c time.Time, d func(int) error, e func(int, int) (int, error), f ...time.Time) (r string, err error) {
        }
      EOF
      split = <<-EOF
        func Func(
        a, b int,
        c time.Time,
        d func(int) error,
        e func(int, int) (int, error),
        f ...time.Time,
        ) (r string, err error) {
        }
      EOF
      joined = <<-EOF
        func Func(a, b int, c time.Time, d func(int) error, e func(int, int) (int, error), f ...time.Time) (r string, err error) {
        }
      EOF
      assert_split_join(initial, split, joined)
    end

    it "handles method definitions" do
      initial = <<-EOF
        func (r Receiver) Method(a, b int, c time.Time, d func(int) error, e func(int, int) (int, error), f ...time.Time) {
        }
      EOF
      split = <<-EOF
        func (r Receiver) Method(
        a, b int,
        c time.Time,
        d func(int) error,
        e func(int, int) (int, error),
        f ...time.Time,
        ) {
        }
      EOF
      joined = <<-EOF
        func (r Receiver) Method(a, b int, c time.Time, d func(int) error, e func(int, int) (int, error), f ...time.Time) {
        }
      EOF
      assert_split_join(initial, split, joined)
    end

    it "handles method definitions with return types" do
      initial = <<-EOF
        func (r Receiver) Method(a, b int, c time.Time, d func(int) error, e func(int, int) (int, error), f ...time.Time) (r string, err error) {
        }
      EOF
      split = <<-EOF
        func (r Receiver) Method(
        a, b int,
        c time.Time,
        d func(int) error,
        e func(int, int) (int, error),
        f ...time.Time,
        ) (r string, err error) {
        }
      EOF
      joined = <<-EOF
        func (r Receiver) Method(a, b int, c time.Time, d func(int) error, e func(int, int) (int, error), f ...time.Time) (r string, err error) {
        }
      EOF
      assert_split_join(initial, split, joined)
    end
  end

  specify "func calls" do
    set_file_contents <<-EOF
      err := Func(a, b, c, d)
    EOF
    setup_go_filetype

    vim.search 'a,'
    split

    # In case there is no Go installed, deindent everything:
    vim.normal '6<<6<<6<<6<<6<<'
    vim.write

    assert_file_contents <<-EOF
      err := Func(
      a,
      b,
      c,
      d,
      )
    EOF

    join

    assert_file_contents <<-EOF
      err := Func(a, b, c, d)
    EOF
  end
end
