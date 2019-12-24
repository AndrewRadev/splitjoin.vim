require 'spec_helper'

describe "go" do
  let(:filename) { 'test.go' }

  # Go is not built-in, so let's set it up manually
  def setup_go_filetype
    vim.set(:filetype, 'go')
  end

  def deindent_everything
    vim.command '%s/^\s*//g'
    vim.write
    vim.normal 'gg'
  end

  specify "imports" do
    set_file_contents <<~EOF
      import "fmt"
    EOF
    setup_go_filetype

    vim.search('import')
    split
    deindent_everything

    assert_file_contents <<~EOF
    import (
    "fmt"
    )
    EOF

    vim.search('import')
    join

    assert_file_contents <<~EOF
      import "fmt"
    EOF
  end

  specify "var/const modifiers" do
    set_file_contents <<~EOF
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

    deindent_everything

    assert_file_contents <<~EOF
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

    assert_file_contents <<~EOF
      var foo string
      const bar string
      type ChanDir int
    EOF
  end

  specify "structs" do
    set_file_contents <<~EOF
      StructType{one: 1, two: "asdf", three: []int{1, 2, 3}}
    EOF
    setup_go_filetype

    vim.search 'one:'
    split

    deindent_everything

    assert_file_contents <<~EOF
      StructType{
      one: 1,
      two: "asdf",
      three: []int{1, 2, 3},
      }
    EOF

    join

    assert_file_contents <<~EOF
      StructType{ one: 1, two: "asdf", three: []int{1, 2, 3} }
    EOF
  end

  specify "structs without padding" do
    set_file_contents <<~EOF
      StructType{one: 1, two: "asdf", three: []int{1, 2, 3}}
    EOF
    setup_go_filetype
    vim.command('let b:splitjoin_curly_brace_padding = 0')

    vim.search 'one:'
    split

    deindent_everything

    assert_file_contents <<~EOF
      StructType{
      one: 1,
      two: "asdf",
      three: []int{1, 2, 3},
      }
    EOF

    join

    assert_file_contents <<~EOF
      StructType{one: 1, two: "asdf", three: []int{1, 2, 3}}
    EOF
  end

  describe "funcs" do
    def assert_split_join(initial, split_expected, join_expected)
      set_file_contents initial
      setup_go_filetype
      vim.search 'Func(\zs\k'

      split
      deindent_everything

      assert_file_contents split_expected

      join

      assert_file_contents join_expected
    end

    it "handles function definitions" do
      initial = <<~EOF
        func Func(a, b int, c time.Time, d func(int) error, e func(int, int) (int, error), f ...time.Time) {
        }
      EOF
      split = <<~EOF
        func Func(
        a, b int,
        c time.Time,
        d func(int) error,
        e func(int, int) (int, error),
        f ...time.Time,
        ) {
        }
      EOF
      joined = <<~EOF
        func Func(a, b int, c time.Time, d func(int) error, e func(int, int) (int, error), f ...time.Time) {
        }
      EOF
      assert_split_join(initial, split, joined)
    end

    it "handles function definitions with return types" do
      initial = <<~EOF
        func Func(a, b int, c time.Time, d func(int) error, e func(int, int) (int, error), f ...time.Time) (r string, err error) {
        }
      EOF
      split = <<~EOF
        func Func(
        a, b int,
        c time.Time,
        d func(int) error,
        e func(int, int) (int, error),
        f ...time.Time,
        ) (r string, err error) {
        }
      EOF
      joined = <<~EOF
        func Func(a, b int, c time.Time, d func(int) error, e func(int, int) (int, error), f ...time.Time) (r string, err error) {
        }
      EOF
      assert_split_join(initial, split, joined)
    end

    it "handles method definitions" do
      initial = <<~EOF
        func (r Receiver) Func(a, b int, c time.Time, d func(int) error, e func(int, int) (int, error), f ...time.Time) {
        }
      EOF
      split = <<~EOF
        func (r Receiver) Func(
        a, b int,
        c time.Time,
        d func(int) error,
        e func(int, int) (int, error),
        f ...time.Time,
        ) {
        }
      EOF
      joined = <<~EOF
        func (r Receiver) Func(a, b int, c time.Time, d func(int) error, e func(int, int) (int, error), f ...time.Time) {
        }
      EOF
      assert_split_join(initial, split, joined)
    end

    it "handles method definitions with return types" do
      initial = <<~EOF
        func (r Receiver) Func(a, b int, c time.Time, d func(int) error, e func(int, int) (int, error), f ...time.Time) (r string, err error) {
        }
      EOF
      split = <<~EOF
        func (r Receiver) Func(
        a, b int,
        c time.Time,
        d func(int) error,
        e func(int, int) (int, error),
        f ...time.Time,
        ) (r string, err error) {
        }
      EOF
      joined = <<~EOF
        func (r Receiver) Func(a, b int, c time.Time, d func(int) error, e func(int, int) (int, error), f ...time.Time) (r string, err error) {
        }
      EOF
      assert_split_join(initial, split, joined)
    end
  end

  specify "func calls" do
    set_file_contents <<~EOF
      err := Func(a, b, c, d)
    EOF
    setup_go_filetype

    vim.search 'a,'
    split
    deindent_everything

    assert_file_contents <<~EOF
      err := Func(
      a,
      b,
      c,
      d,
      )
    EOF

    join

    assert_file_contents <<~EOF
      err := Func(a, b, c, d)
    EOF
  end

  specify "func definition bodies" do
    set_file_contents <<~EOF
      func foo(x, y int) bool { return x+y == 5 }
    EOF
    setup_go_filetype

    vim.search 'return'
    split
    deindent_everything

    assert_file_contents <<~EOF
      func foo(x, y int) bool {
      return x+y == 5
      }
    EOF

    join

    assert_file_contents <<~EOF
      func foo(x, y int) bool { return x+y == 5 }
    EOF
  end
end
