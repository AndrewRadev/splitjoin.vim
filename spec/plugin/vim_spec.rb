require 'spec_helper'

describe "vim" do
  let(:filename) { "test.vim" }

  before :each do
    vim.set 'expandtab'
    vim.set 'shiftwidth', 2
  end

  specify ":if commands" do
    contents = <<-EOF
      if condition == 1
        return 0
      endif
    EOF

    set_file_contents contents

    join
    assert_file_contents "if condition == 1 | return 0 | endif"

    split
    assert_file_contents contents
  end
end
