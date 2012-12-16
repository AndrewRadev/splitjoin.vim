require 'spec_helper'

describe "sh" do
  let(:vim) { VIM }
  let(:filename) { 'test.sh' }

  specify "splitjoining by semicolon" do
    set_file_contents <<-EOF
      echo "one"; echo "two"
    EOF

    split

    assert_file_contents <<-EOF
      echo "one"
      echo "two"
    EOF

    vim.search('one')
    join

    assert_file_contents <<-EOF
      echo "one"; echo "two"
    EOF
  end
end
