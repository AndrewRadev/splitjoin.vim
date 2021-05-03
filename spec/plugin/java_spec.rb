require 'spec_helper'

describe "java" do
  let(:filename) { 'test.java' }

  before :each do
    vim.set(:expandtab)
    vim.set(:shiftwidth, 2)
  end

  specify "if-clause" do
    set_file_contents "if (foo && bar) { baz; }"

    vim.search 'if'
    split

    assert_file_contents <<~EOF
      if (foo && bar) {
        baz;
      }
    EOF

    join

    assert_file_contents "if (foo && bar) { baz; }"
  end

  specify "function_call" do
    set_file_contents "myfunction(lots, of, different, parameters);"

    vim.search '('
    split

    assert_file_contents <<~EOF
      myfunction(lots,
          of,
          different,
          parameters);
    EOF

    join

    assert_file_contents "myfunction(lots, of, different, parameters);"
  end

  specify "ignores strings" do
    set_file_contents "\"myfunction(several, parameters)\""

    vim.search '('
    split

    assert_file_contents "\"myfunction(several, parameters)\""
  end

  specify "ignores comments" do
    set_file_contents "/* myfunction(several, parameters) */"

    vim.search '('
    split

    assert_file_contents "/* myfunction(several, parameters) */"
  end
end
