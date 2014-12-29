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

  describe "attributes" do
    let(:long_list_joined) do
      '<div id="test" class="foo bar baz" style="width: 500px; height: 500px"></div>'
    end

    let(:long_list_split) do
      <<-EOF
        <div
          id="test"
          class="foo bar baz"
          style="width: 500px; height: 500px">
        </div>'
      EOF
    end

    let(:short_list_joined) { '<div id="test" class="foo bar baz"></div>' }
    let(:short_list_split) { %{<div id="test" class="foo bar baz">\n\n</div>} }

    specify "with a long list" do
      simple_test(long_list_joined, long_list_split)
    end

    specify "with a short list" do
      simple_test(short_list_joined, short_list_split)
    end
  end
end

