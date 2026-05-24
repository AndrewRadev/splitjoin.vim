require 'spec_helper'

describe "dot" do
  let(:filename) { 'test.dot' }

  specify "statements" do
    set_file_contents "A, B -> C -> D -> E; X -> Y;"

    split

    assert_file_contents <<-EOF
      A, B -> C -> D -> E;
      X -> Y;
    EOF

    join

    assert_file_contents "A, B -> C -> D -> E; X -> Y;"
  end

  specify "edges" do
    set_file_contents "A, B -> C -> D -> E;"

    split

    assert_file_contents <<-EOF
      A, B -> C;
      C -> D;
      D -> E;
    EOF

    join

    assert_file_contents <<-EOF
      A, B -> C -> D;
      D -> E;
    EOF

    join

    assert_file_contents "A, B -> C -> D -> E;"
  end
end
