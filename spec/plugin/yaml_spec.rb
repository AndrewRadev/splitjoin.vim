require 'spec_helper'

describe "yaml" do
  let(:filename) { 'test.yml' }

  before :each do
    vim.set 'expandtab'
    vim.set 'shiftwidth', 2
  end

  describe "arrays" do
    specify "basic" do
      set_file_contents <<~EOF
        root:
          one: [1, 2]
          two: ['three', 'four']
      EOF

      vim.search 'one'
      split
      vim.search 'two'
      split

      assert_file_contents <<~EOF
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

      assert_file_contents <<~EOF
        root:
          one: [1, 2]
          two: ['three', 'four']
      EOF
    end

    specify "with empty spaces" do
      set_file_contents <<~EOF
        root:
          - 'one'

          - 'two'

      EOF

      vim.search 'root'
      join

      assert_file_contents <<~EOF
        root: ['one', 'two']
      EOF
    end

    specify "with strings containing a colon" do
      set_file_contents <<~EOF
        root:
          - 'one: foo'
          - 'two: bar'
      EOF

      vim.search 'root'
      join

      assert_file_contents <<~EOF
        root: ['one: foo', 'two: bar']
      EOF

      vim.search 'root'
      split

      assert_file_contents <<~EOF
        root:
          - 'one: foo'
          - 'two: bar'
      EOF
    end

    specify "with strings containing a comma" do
      set_file_contents <<~EOF
        root:
          - 'one, foo'
          - 'two, bar'

      EOF

      vim.search 'root'
      join

      assert_file_contents <<~EOF
        root: ['one, foo', 'two, bar']
      EOF

      vim.search 'root'
      split

      assert_file_contents <<~EOF
        root:
          - 'one, foo'
          - 'two, bar'
      EOF
    end

    specify "nested objects inside an array" do
      set_file_contents <<~EOF
        root:
          - one: { foo: bar }
      EOF

      vim.search 'one'
      split

      assert_file_contents <<~EOF
        root:
          - one:
              foo: bar
      EOF
    end

    specify "list of simple objects" do
      set_file_contents <<~EOF
        list: [{ prop: 1 }, { prop: 2 }]
      EOF

      vim.search 'list'
      split

      assert_file_contents <<~EOF
        list:
          - prop: 1
          - prop: 2
      EOF

      vim.search 'list'
      join

      assert_file_contents <<~EOF
        list: [{ prop: 1 }, { prop: 2 }]
      EOF
    end

    specify "containing mixed elements" do
      set_file_contents <<~EOF
        list: [{ prop: 1 }, { a: 1, b: 2 }, "a: b"]
      EOF

      vim.search 'list'
      split

      assert_file_contents <<~EOF
        list:
          - prop: 1
          - { a: 1, b: 2 }
          - "a: b"
      EOF

      vim.search 'list'
      join

      assert_file_contents <<~EOF
        list: [{ prop: 1 }, { a: 1, b: 2 }, "a: b"]
      EOF
    end

    specify "preserve empty lines" do
      set_file_contents <<~EOF
        list:
          - 1

        end: true
      EOF

      vim.search 'list'
      join

      assert_file_contents <<~EOF
        list: [1]

        end: true
      EOF

      vim.search 'list'
      split

      assert_file_contents <<~EOF
        list:
          - 1

        end: true
      EOF
    end
  end

  describe "maps" do
    specify "basic" do
      set_file_contents <<~EOF
        root:
          one: { foo: bar }
          two: { three: ['four', 'five'], six: seven }
      EOF

      vim.search 'one'
      split
      vim.search 'two'
      split

      assert_file_contents <<~EOF
        root:
          one:
            foo: bar
          two:
            three: ['four', 'five']
            six: seven
      EOF

      vim.search 'one'
      join
      vim.search 'two'
      join

      assert_file_contents <<~EOF
        root:
          one: { foo: bar }
          two: { three: ['four', 'five'], six: seven }
      EOF
    end

    specify "preserve empty lines" do
      set_file_contents <<~EOF
        map:
          one: 1

        end: true
      EOF

      vim.search ''
      join

      assert_file_contents <<~EOF
        map: { one: 1 }

        end: true
      EOF

      vim.search 'map'
      split

      assert_file_contents <<~EOF
        map:
          one: 1

        end: true
      EOF
    end
  end
end
