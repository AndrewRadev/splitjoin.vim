require 'spec_helper'

# Note: Handlebars is not a built-in filetype, so these specs work with no
# automatic indentation. It's still possible that bugs would creep in due when
# real indentation is factored in, though I've attempted to minimize the
# effects of that.
#
describe "handlebars" do
  let(:filename) { 'test.hbs' }

  # Coffee is not built-in, so let's set it up manually
  def setup_handlebars_filetype
    vim.set(:filetype, 'html.handlebars')
    vim.set(:expandtab)
    vim.set(:shiftwidth, 2)
  end

  specify "components" do
    set_file_contents "{{some/component-name foo=bar bar=baz}}"
    setup_handlebars_filetype

    split

    assert_file_contents <<-EOF
      {{some/component-name
      foo=bar
      bar=baz}}
    EOF

    join

    assert_file_contents "{{some/component-name foo=bar bar=baz}}"
  end
end
