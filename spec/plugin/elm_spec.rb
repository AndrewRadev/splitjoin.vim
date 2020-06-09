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

      specify 'with a sub-list in a list of list' do
        set_file_contents <<~EOF
          list =
              [ [123, 456]
              , [78, 89, 90]
              ]
        EOF

        vim.search '123'
        split

        assert_file_contents <<~EOF
          list =
              [ [ 123
              , 456
              ]
              , [78, 89, 90]
              ]
        EOF
        # there is kind of a bug in the syntax here
        # it should indent the sub-list instead, like:
        #
        # list =
        #     [ [ 123
        #       , 456
        #     ]
        #     , [78, 89, 90]
        #     ]
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

      specify 'with a list of only one element' do
        set_file_contents <<~EOF
          list =
              [(1, "\\"two, three, four")]
        EOF

        vim.search '['
        split

        assert_file_contents <<~EOF
          list =
              [(1, "\\"two, three, four")]
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

  describe 'splitting/joining a tuple' do
    describe 'splitting a tuple' do
      specify 'with a simple tuple' do
        set_file_contents <<~EOF
          tuple =
              (123, "blah", pi)
        EOF

        vim.search '('
        split

        assert_file_contents <<~EOF
          tuple =
              ( 123
              , "blah"
              , pi
              )
        EOF
      end

      specify 'with a tuple holding tricky content' do
        set_file_contents <<~EOF
          tuple =
              (("\\" (booh, gotcha!)"), [(pi / 6, rotate <| square)], (12, 43))
        EOF

        vim.search '('
        split

        assert_file_contents <<~EOF
          tuple =
              ( ("\\" (booh, gotcha!)")
              , [(pi / 6, rotate <| square)]
              , (12, 43)
              )
        EOF
      end

      specify 'with something that is not a tuple' do
        set_file_contents <<~EOF
          not_a_tuple =
              ([1, 2, 3, 4] |> List.map ((*) 2))
        EOF

        vim.search '('
        split

        assert_file_contents <<~EOF
          not_a_tuple =
              ([1, 2, 3, 4] |> List.map ((*) 2))
        EOF
      end
    end
  end
end
