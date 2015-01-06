require 'spec_helper'

describe "html" do
  let(:filename) { 'test.html' }

  before :each do
    vim.set(:expandtab)
    vim.set(:shiftwidth, 2)
  end

  def simple_test(joined_html, split_html)
    set_file_contents joined_html
    split
    assert_file_contents split_html
    join
    assert_file_contents joined_html
  end

  specify "tags" do
    joined_html = '<div class="foo">bar</div>'

    split_html = <<-EOF
      <div class="foo">
        bar
      </div>
    EOF

    simple_test(joined_html, split_html)
  end

  specify "attributes" do
    joined_html = '<div id="test" token class="foo bar baz" style="width: 500px; height: 500px">'
    split_html = <<-EOF
      <div
        id="test"
        token
        class="foo bar baz"
        style="width: 500px; height: 500px">
    EOF

    simple_test(joined_html, split_html)
  end
end

