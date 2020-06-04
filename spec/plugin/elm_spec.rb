# frozen_string_literal: true

require 'spec_helper'

describe 'elm' do
  let(:filename) { 'Test.elm' }

  before :each do
    vim.set(:expandtab)
    vim.set(:shiftwidth, 4)
  end

  describe 'splitting/joining a list' do
    describe 'splitting a list' do
      specify 'with a simple list' do
        set_file_contents <<~EOF
          list =
              [1, 22, 333, 4444]
        EOF

        vim.search '['
        split

        assert_file_contents <<~EOF
          list =
              [ 1
              , 22
              , 333
              , 4444
              ]
        EOF
      end

      specify 'with a space and tab-riddled list' do
        set_file_contents <<~EOF
          list =
              [ \t1\t , \t22,\t 333 , \t4444\t ]
        EOF

        vim.search '['
        split

        assert_file_contents <<~EOF
          list =
              [ 1
              , 22
              , 333
              , 4444
              ]
        EOF
      end

      specify 'with a list holding function call results' do
        set_file_contents <<~EOF
          list =
              [1 + 2, modBy 3 4, remBy 5 (num + 6), maybeNum |> Maybe.withDefault 7]
        EOF

        vim.search '['
        split

        assert_file_contents <<~EOF
          list =
              [ 1 + 2
              , modBy 3 4
              , remBy 5 (num + 6)
              , maybeNum |> Maybe.withDefault 7
              ]
        EOF
      end

      specify 'with a list of lists' do
        set_file_contents <<~EOF
          list =
              [[123, 456], [78, 89, 90]]
        EOF

        vim.search '['
        split

        assert_file_contents <<~EOF
          list =
              [ [123, 456]
              , [78, 89, 90]
              ]
        EOF
      end

      specify 'with a list of tuples' do
        set_file_contents <<~EOF
          list =
              [(123, 456), (78, 89)]
        EOF

        vim.search '['
        split

        assert_file_contents <<~EOF
          list =
              [ (123, 456)
              , (78, 89)
              ]
        EOF
      end

      specify 'with a list of messy strings' do
        set_file_contents <<~EOF
          list =
              ["One, two", "\\"One, two\\", \\"three, four\\""]
        EOF

        vim.search '['
        split

        assert_file_contents <<~EOF
          list =
              [ "One, two"
              , "\\"One, two\\", \\"three, four\\""
              ]
        EOF
      end
    end

    xspecify 'joining a list' do
      set_file_contents <<~EOF
        list =
            [ 1
            , 2
            , 3
            , 4
            ]
      EOF

      vim.search '['
      join

      assert_file_contents <<~EOF
        list =
          [1, 2, 3, 4]
      EOF
    end
  end
end
