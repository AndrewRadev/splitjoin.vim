require 'spec_helper'

describe "elixir" do
  let(:filename) { "test.ex" }

  before :each do
    vim.set(:expandtab)
    vim.set(:shiftwidth, 2)
  end

  describe "function definitions" do
    specify "0 arity" do
      set_file_contents <<~EOF
        defmodule Foo do
          def bar() do
            :bar
          end
        end
      EOF

      vim.search 'def bar'
      join

      assert_file_contents <<~EOF
        defmodule Foo do
          def bar(), do: :bar
        end
      EOF

      vim.search 'def bar'
      split

      assert_file_contents <<~EOF
        defmodule Foo do
          def bar() do
            :bar
          end
        end
      EOF
    end

    specify "0 arity no parens" do
      set_file_contents <<~EOF
        defmodule Foo do
          def bar do
            :bar
          end
        end
      EOF

      vim.search 'def bar'
      join

      assert_file_contents <<~EOF
        defmodule Foo do
          def bar, do: :bar
        end
      EOF

      vim.search 'def bar'
      split

      assert_file_contents <<~EOF
        defmodule Foo do
          def bar do
            :bar
          end
        end
      EOF
    end

    specify "1 arity" do
      set_file_contents <<~EOF
        defmodule Foo do
          def bar(foo) do
            :bar
          end
        end
      EOF

      vim.search 'def bar'
      join

      assert_file_contents <<~EOF
        defmodule Foo do
          def bar(foo), do: :bar
        end
      EOF

      vim.search 'def bar'
      split

      assert_file_contents <<~EOF
        defmodule Foo do
          def bar(foo) do
            :bar
          end
        end
      EOF
    end
  end

  describe "do-blocks" do
    specify "with round brackets" do
      set_file_contents <<~EOF
        let(:one, do: two() |> three(four()))
      EOF

      vim.search ':one'
      split

      assert_file_contents <<~EOF
        let(:one) do
          two() |> three(four())
        end
      EOF

      join

      assert_file_contents <<~EOF
        let(:one, do: two() |> three(four()))
      EOF
    end

    specify "with no brackets" do
      set_file_contents <<~EOF
        let :one, do: two() |> three(four())
      EOF

      vim.search ':one'
      split

      assert_file_contents <<~EOF
        let :one do
          two() |> three(four())
        end
      EOF

      join

      assert_file_contents <<~EOF
        let :one, do: two() |> three(four())
      EOF
    end
  end

  describe "if-blocks" do
    specify "with no brackets" do
      set_file_contents <<~EOF
        if 2 > 1, do: print("OK"), else: print("Not OK")
      EOF

      vim.search '2 > 1'
      split

      assert_file_contents <<~EOF
        if 2 > 1 do
          print("OK")
        else
          print("Not OK")
        end
      EOF

      join

      assert_file_contents <<~EOF
        if 2 > 1, do: print("OK"), else: print("Not OK")
      EOF
    end

    specify "with round brackets" do
      set_file_contents <<~EOF
        if(2 > 1, do: print("OK"), else: print("Not OK"))
      EOF

      vim.search '2 > 1'
      split

      assert_file_contents <<~EOF
        if 2 > 1 do
          print("OK")
        else
          print("Not OK")
        end
      EOF

      join

      assert_file_contents <<~EOF
        if 2 > 1, do: print("OK"), else: print("Not OK")
      EOF
    end
  end

  describe "joining comma-separated arguments" do
    specify "with a level of indent" do
      set_file_contents <<~EOF
        for a <- 1..10,
          Integer.is_odd(a) do
          a
        end
      EOF

      vim.search 'for'
      join

      assert_file_contents <<~EOF
        for a <- 1..10, Integer.is_odd(a) do
          a
        end
      EOF
    end

    specify "with no indent" do
      set_file_contents <<~EOF
        for a <- 1..10,
        Integer.is_odd(a) do
          a
        end
      EOF

      vim.search 'for'
      join

      assert_file_contents <<~EOF
        for a <- 1..10, Integer.is_odd(a) do
          a
        end
      EOF
    end

    specify "multiple lines" do
      set_file_contents <<~EOF
        if Enum.member?(one, two),
          do: query |> where(three, four),
          else: five
      EOF

      vim.search 'Enum'
      join

      assert_file_contents <<~EOF
        if Enum.member?(one, two), do: query |> where(three, four), else: five
      EOF
    end
  end

  specify "arrays" do
    set_file_contents <<~EOF
      [a, b, c]
    EOF

    split

    assert_file_contents <<~EOF
      [
        a,
        b,
        c
      ]
    EOF

    vim.search('[')
    join

    assert_file_contents <<~EOF
      [a, b, c]
    EOF

    set_file_contents <<~EOF
      [a: 1, b: 2, c: %{a: 1, b: 2}]
    EOF

    split

    assert_file_contents <<~EOF
      [
        a: 1,
        b: 2,
        c: %{a: 1, b: 2}
      ]
    EOF

    vim.search('[')
    join

    assert_file_contents <<~EOF
      [a: 1, b: 2, c: %{a: 1, b: 2}]
    EOF

    set_file_contents <<~EOF
      []
    EOF

    vim.search('[')
    split

    assert_file_contents <<~EOF
      []
    EOF

    vim.search('[')
    join

    assert_file_contents <<~EOF
      []
    EOF
  end
end
