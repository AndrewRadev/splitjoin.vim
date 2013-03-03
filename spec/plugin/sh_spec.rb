require 'spec_helper'

describe "sh" do
  let(:filename) { 'test.sh' }

  describe "splitjoining by semicolon" do
    specify "simple case" do
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

    specify "skipping semicolons in strings" do
      set_file_contents <<-EOF
        echo "one;two"; echo "three"
      EOF

      split

      assert_file_contents <<-EOF
        echo "one;two"
        echo "three"
      EOF
    end

    specify "skipping semicolons in groups with braces" do
      set_file_contents <<-EOF
        echo "one"; (echo "two"; echo "three") &; echo "four"
      EOF

      split

      assert_file_contents <<-EOF
        echo "one"
        (echo "two"; echo "three") &
        echo "four"
      EOF
    end
  end
end

