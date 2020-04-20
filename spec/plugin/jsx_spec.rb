require 'spec_helper'

describe "JSX" do
  let(:filename) { 'test.jsx' }

  def setup_filetype
    vim.set(:filetype, 'javascriptreact')
    vim.set(:expandtab)
    vim.set(:shiftwidth, 2)
  end

  describe "self-closing tags" do
    specify "basic" do
      set_file_contents 'let button = <Button />;'
      setup_filetype

      vim.search 'Button'
      split
      remove_indentation

      assert_file_contents <<~EOF
        let button = <Button>
        </Button>;
      EOF

      join

      assert_file_contents 'let button = <Button />;'
    end

    specify "joining on a single line" do
      set_file_contents 'let button = <Button prop="value"></Button>;'
      setup_filetype

      vim.search 'Button'
      join
      remove_indentation

      assert_file_contents <<~EOF
        let button = <Button prop="value" />;
      EOF
    end

    specify "with attributes" do
      set_file_contents 'let button = <Button foo="bar" bar="baz" />;'
      setup_filetype

      vim.search 'Button'
      split
      remove_indentation

      assert_file_contents <<~EOF
        let button = <Button
        foo="bar"
        bar="baz" />;
      EOF

      split
      remove_indentation

      assert_file_contents <<~EOF
        let button = <Button
        foo="bar"
        bar="baz">
        </Button>;
      EOF

      vim.search '<Button'
      join
      remove_indentation

      assert_file_contents <<~EOF
        let button = <Button foo="bar" bar="baz">
        </Button>;
      EOF

      join
      remove_indentation

      assert_file_contents 'let button = <Button foo="bar" bar="baz" />;'
    end
  end
end
