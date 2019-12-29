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
        list: [{ aprop: 1 }, { aProp: 2 }, { 'a:prop': 3 }, { a prop: 4 }]
      EOF

      vim.search 'list'
      split

      assert_file_contents <<~EOF
        list:
          - aprop: 1
          - aProp: 2
          - 'a:prop': 3
          - a prop: 4
      EOF

      vim.search 'list'
      join

      assert_file_contents <<~EOF
        list: [{ aprop: 1 }, { aProp: 2 }, { 'a:prop': 3 }, { a prop: 4 }]
      EOF
    end

    specify "containing mixed elements" do
      set_file_contents <<~EOF
        list: [{ prop: 1 }, { a: 1, b: 2 }, "a: b", { a value: 1, 'a:value': 2, aValue: 3 }]
      EOF

      vim.search 'list'
      split

      assert_file_contents <<~EOF
        list:
          - prop: 1
          - { a: 1, b: 2 }
          - "a: b"
          - { a value: 1, 'a:value': 2, aValue: 3 }
      EOF

      vim.search 'list'
      join

      assert_file_contents <<~EOF
        list: [{ prop: 1 }, { a: 1, b: 2 }, "a: b", { a value: 1, 'a:value': 2, aValue: 3 }]
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

    specify "containing mulitline maps" do
      pending 'Not implemented'

      set_file_contents <<~EOF
        list:
          - one: 1
            two: 2
      EOF

      vim.search 'list'
      join

      assert_file_contents <<~EOF
        list: [{ one: 1, two: 2 }]
      EOF
    end

    specify "containing arrays" do
      pending 'Not implemented'

      set_file_contents <<~EOF
        list:
          - - 1
            - 2
      EOF

      vim.search 'list'
      join

      assert_file_contents <<~EOF
        list: [[1, 2]]
      EOF
    end

    specify "inside an array" do
      set_file_contents <<~EOF
        list:
          - - 1
            - 2
      EOF

      vim.search '1'
      join

      assert_file_contents <<~EOF
        list:
          - [1, 2]
      EOF
    end

    specify "split nested arrays" do
      set_file_contents <<~EOF
        list: [[[1, 2]]]
      EOF

      vim.search 'list'
      split

      assert_file_contents <<~EOF
        list:
          - [[1, 2]]
      EOF

      vim.search '1'
      split

      assert_file_contents <<~EOF
        list:
          - - [1, 2]
      EOF

      vim.search '1'
      split

      assert_file_contents <<~EOF
        list:
          - - - 1
              - 2
      EOF
    end

    specify "join nested arrays" do
      set_file_contents <<~EOF
        list:
          - - - 1
              - 2
      EOF

      vim.search '1'
      join

      assert_file_contents <<~EOF
        list:
          - - [1, 2]
      EOF

      vim.search '1'
      join

      assert_file_contents <<~EOF
        list:
          - [[1, 2]]
      EOF

      vim.search 'list'
      join

      assert_file_contents <<~EOF
        list: [[[1, 2]]]
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

    specify "complex keys" do
      set_file_contents <<~EOF
        map:
          one value: 1
          'my:key': 2
      EOF

      vim.search 'root'
      join

      assert_file_contents <<~EOF
        map: { one value: 1, 'my:key': 2 }
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

    specify "joining inside an array" do
      pending 'Not implemented'

      set_file_contents <<~EOF
        list:
          - one: 1
            two: 2
        end: true
      EOF

      vim.search 'one:'
      join

      assert_file_contents <<~EOF
        list:
          - { one: 1, two: 2 }
        end: true
      EOF
    end

    specify "splitting inside an array" do
      set_file_contents <<~EOF
        list:
          - { one: 1, two: 2 }
        end: true
      EOF

      vim.search 'one:'
      split

      assert_file_contents <<~EOF
        list:
          - one: 1
            two: 2
        end: true
      EOF
    end

    specify "splitting inside an array and map" do
      set_file_contents <<~EOF
        list:
          - foo: { one: 1, two: 2 }
        end: true
      EOF

      vim.search 'foo:'
      split

      assert_file_contents <<~EOF
        list:
          - foo:
              one: 1
              two: 2
        end: true
      EOF
    end

  end
end
