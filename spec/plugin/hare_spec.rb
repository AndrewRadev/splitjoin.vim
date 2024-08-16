require 'spec_helper'

describe "hare" do
  let(:filename) { 'test.ha' }

  specify "question mark operator" do
    set_file_contents <<~EOF
      const num = getnumber()?;
    EOF

    vim.search('getnumber')
    split

    assert_file_contents <<~EOF
      const num = match (getnumber()) {
      case error => abort();
      case let t: type =>
      	yield t;
      };
    EOF
  end
end
