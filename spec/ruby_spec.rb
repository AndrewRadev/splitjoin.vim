require 'spec_helper'

describe "ruby" do
  let(:vim) { VIM }

  specify "if-clauses" do
    set_file_contents <<-EOF
      return "the answer" if 6 * 9 == 42
    EOF

    split

    assert_file_contents <<-EOF
      if 6 * 9 == 42
        return "the answer"
      end
    EOF

    vim.search 'if'
    join

    assert_file_contents <<-EOF
      return "the answer" if 6 * 9 == 42
    EOF
  end

  specify "hashes" do
    set_file_contents <<-EOF
      foo = { :bar => 'baz', :one => 'two' }
    EOF

    vim.search ':bar'
    split

    assert_file_contents <<-EOF
      foo = {
        :bar => 'baz',
        :one => 'two'
      }
    EOF

    vim.search 'foo'
    join

    assert_file_contents <<-EOF
      foo = { :bar => 'baz', :one => 'two' }
    EOF
  end

  # TODO (2012-05-24) Indentation breaks the "end" matching logic
  xspecify "caching constructs" do
    set_file_contents <<-EOF
      @two ||= 1 + 1
    EOF

    split

    assert_file_contents <<-EOF
      @two ||= begin
                 1 + 1
               end
    EOF

    join

    assert_file_contents <<-EOF
      @two ||= 1 + 1
    EOF
  end

  specify "blocks" do
    set_file_contents <<-EOF
      Bar.new { |b| puts b.to_s }
    EOF

    split

    assert_file_contents <<-EOF
      Bar.new do |b|
        puts b.to_s
      end
    EOF

    join

    assert_file_contents <<-EOF
      Bar.new { |b| puts b.to_s }
    EOF
  end
end
