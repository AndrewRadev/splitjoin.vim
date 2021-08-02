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
      set_file_contents '<Button />;'
      setup_filetype

      vim.search 'Button'
      split
      remove_indentation

      assert_file_contents <<~EOF
        <Button>
        </Button>;
      EOF

      join

      assert_file_contents '<Button />;'
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
      set_file_contents '<Button foo="bar" bar="baz" />;'
      setup_filetype

      vim.search 'Button'
      split
      remove_indentation

      assert_file_contents <<~EOF
        <Button
        foo="bar"
        bar="baz" />;
      EOF

      split
      remove_indentation

      assert_file_contents <<~EOF
        <Button
        foo="bar"
        bar="baz">
        </Button>;
      EOF

      vim.search '<Button'
      join
      remove_indentation

      assert_file_contents <<~EOF
        <Button foo="bar" bar="baz">
        </Button>;
      EOF

      join
      remove_indentation

      assert_file_contents '<Button foo="bar" bar="baz" />;'
    end
  end

  describe "JSX expressions" do
    specify "self-closing tag with a let statement" do
      set_file_contents 'let button = <Button />;'
      setup_filetype

      vim.search 'Button'
      split
      remove_indentation

      assert_file_contents <<~EOF
        let button = (
        <Button />
        );
      EOF

      vim.search('button = \zs(')
      join

      assert_file_contents 'let button = <Button />;'
    end

    specify "simple tag with a return statement" do
      set_file_contents <<~EOF
        function button() {
          return <Button></Button>;
        }
      EOF
      setup_filetype

      vim.search '<Button'
      split
      remove_indentation

      assert_file_contents <<~EOF
        function button() {
        return (
        <Button></Button>
        );
        }
      EOF

      vim.search('return \zs(')
      join

      assert_file_contents <<~EOF
        function button() {
          return <Button></Button>;
        }
      EOF
    end

    specify "tag with attributes in a lambda" do
      set_file_contents '() => <Button foo="bar" />'
      setup_filetype

      vim.search '<Button'
      split
      remove_indentation

      assert_file_contents <<~EOF
        () => (
        <Button foo="bar" />
        )
      EOF

      vim.search('() => \zs(')
      join

      assert_file_contents '() => <Button foo="bar" />'
    end
  end
end
