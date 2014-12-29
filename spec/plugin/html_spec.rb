require 'spec_helper'

describe "html" do
  let(:filename) { 'test.html' }

  before :each do
    vim.set(:expandtab)
    vim.set(:shiftwidth, 2)
  end

  specify "tags" do
    joined_html = '<div class="foo">bar</div>'

    split_html = <<-EOF
      <div class="foo">
        bar
      </div>
    EOF

    set_file_contents joined_html
    split
    assert_file_contents split_html
    join
    assert_file_contents joined_html
  end
end

