# frozen_string_literal: true

require 'spec_helper'

describe 'elm' do
  let(:filename) { 'Test.elm' }

  before :each do
    vim.set(:expandtab)
    vim.set(:shiftwidth, 4)
  end

  describe 'splitting/joining a list' do
    specify 'splitting a list' do
      set_file_contents <<~EOF
        list =
            [1, 2, 3, 4]
      EOF

      vim.search '['
      split

      assert_file_contents <<~EOF
        list =
            [ 1
            , 2
            , 3
            , 4
            ]
      EOF
    end
  end
end
