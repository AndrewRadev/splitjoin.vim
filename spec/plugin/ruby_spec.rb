require 'spec_helper'

describe "ruby" do
  let(:filename) { 'test.rb' }

  before :each do
    vim.set(:expandtab)
    vim.set(:shiftwidth, 2)
  end

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

  describe "ternaries" do
    it "handles simplistic ternaries" do
      set_file_contents <<-EOF
          condition ? 'this' : 'that'
      EOF

      split

      assert_file_contents <<-EOF
          if condition
            'this'
          else
            'that'
          end
      EOF

      join

      assert_file_contents <<-EOF
          condition ? 'this' : 'that'
      EOF
    end

    it "works with unless" do
      set_file_contents <<-EOF
          unless condition
            x = 'a'
          else
            y = 'b'
          end
      EOF

      join

      assert_file_contents <<-EOF
          condition ? y = 'b' : x = 'a'
      EOF

      split

      assert_file_contents <<-EOF
          if condition
            y = 'b'
          else
            x = 'a'
          end
      EOF
    end

    it "extracts variable assignments" do
      set_file_contents <<-EOF
          if condition
            x = 'a'
          else
            x = 'b'
          end
      EOF

      join

      assert_file_contents <<-EOF
          x = (condition ? 'a' : 'b')
      EOF

      split

      assert_file_contents <<-EOF
          x = if condition
                'a'
              else
                'b'
              end
      EOF
    end

    it "handles assignments when joining, adding parentheses" do
      set_file_contents <<-EOF
          x = if condition
                'a'
              else
                'b'
              end
      EOF

      join

      assert_file_contents <<-EOF
          x = (condition ? 'a' : 'b')
      EOF

      split

      assert_file_contents <<-EOF
          x = if condition
                'a'
              else
                'b'
              end
      EOF
    end

    it "handles different formatting for assignments" do
      set_file_contents <<-EOF
          x = unless condition
           'something'
          else
           'anything'
          end
      EOF

      join

      assert_file_contents <<-EOF
          x = (condition ? 'anything' : 'something')
      EOF

      split

      assert_file_contents <<-EOF
          x = if condition
                'anything'
              else
                'something'
              end
      EOF
    end
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
        :one => 'two',
      }
    EOF

    vim.search 'foo'
    join

    assert_file_contents <<-EOF
      foo = { :bar => 'baz', :one => 'two' }
    EOF
  end

  specify "hashes without a trailing comma" do
    begin
      vim.command('let g:splitjoin_ruby_trailing_comma = 0')

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

    ensure
      vim.command('let g:splitjoin_ruby_trailing_comma = 1')
    end
  end

  specify "caching constructs" do
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

  specify "method continuations" do
    set_file_contents <<-EOF
      one.
        two.
        three
    EOF

    join

    assert_file_contents <<-EOF
      one.two.three
    EOF
  end

  describe "blocks" do
    it "splitjoins {}-blocks and do-end blocks" do
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

    it "handles trailing code" do
      set_file_contents <<-EOF
        Bar.new { |one| two }.map(&:name)
      EOF

      split

      assert_file_contents <<-EOF
        Bar.new do |one|
          two
        end.map(&:name)
      EOF

      join

      assert_file_contents <<-EOF
        Bar.new { |one| two }.map(&:name)
      EOF
    end

    it "doesn't get confused by interpolation" do
      set_file_contents <<-EOF
        foo("\#{one}") { two }
      EOF

      vim.search 'two'
      split

      assert_file_contents <<-EOF
        foo("\#{one}") do
          two
        end
      EOF
    end
  end

  describe "heredocs" do
    it "joins heredocs into single-quoted strings when possible" do
      set_file_contents <<-EOF
        string = <<-ANYTHING
          something, "anything"
        ANYTHING
      EOF

      vim.search 'ANYTHING'
      join

      assert_file_contents <<-EOF
        string = 'something, "anything"'
      EOF
    end

    it "joins heredocs into double-quoted strings when there's a single-quoted string inside" do
      set_file_contents <<-EOF
        string = <<-ANYTHING
          something, 'anything'
        ANYTHING
      EOF

      vim.search 'ANYTHING'
      join

      assert_file_contents <<-EOF
        string = "something, 'anything'"
      EOF
    end

    it "joins heredocs into double-quoted strings when there's interpolation inside" do
      set_file_contents <<-EOF
        string = <<-ANYTHING
          something, \#{anything}
        ANYTHING
      EOF

      vim.search 'ANYTHING'
      join

      assert_file_contents <<-EOF
        string = "something, \#{anything}"
      EOF
    end

    it "splits normal strings into heredocs" do
      set_file_contents 'string = "\"anything\""'

      vim.search 'anything'
      split

      assert_file_contents <<-OUTER
        string = <<-EOF
        "anything"
        EOF
      OUTER
    end

    it "splits empty strings into empty heredocs" do
      set_file_contents 'string = ""'

      vim.search '"'
      split

      assert_file_contents <<-OUTER
        string = <<-EOF
        EOF
      OUTER
    end

    it "can use the << heredoc style" do
      begin
        vim.command('let g:splitjoin_ruby_heredoc_type = "<<"')

        set_file_contents <<-EOF
          do
            string = "something"
          end
        EOF

        vim.search 'something'
        split

        assert_file_contents <<-OUTER
          do
            string = <<EOF
          something
          EOF
          end
        OUTER

      ensure
        vim.command('let g:splitjoin_ruby_heredoc_type = "<<-"')
      end
    end
  end

  describe "method options" do
    specify "with curly braces" do
      vim.command('let g:splitjoin_ruby_curly_braces = 1')

      set_file_contents <<-EOF
        foo 1, 2, :one => 1, :two => 2
      EOF

      split

      assert_file_contents <<-EOF
        foo 1, 2, {
          :one => 1,
          :two => 2,
        }
      EOF

      join

      assert_file_contents <<-EOF
        foo 1, 2, { :one => 1, :two => 2 }
      EOF
    end

    specify "without curly braces" do
      vim.command('let g:splitjoin_ruby_curly_braces = 0')

      set_file_contents <<-EOF
        foo 1, 2, :one => 1, :two => 2
      EOF

      split

      assert_file_contents <<-EOF
        foo 1, 2,
          :one => 1,
          :two => 2
      EOF

      join

      assert_file_contents <<-EOF
        foo 1, 2, :one => 1, :two => 2
      EOF
    end

    specify "with round braces" do
      vim.command('let g:splitjoin_ruby_curly_braces = 0')

      set_file_contents <<-EOF
        foo(:one => 1, :two => 2)
      EOF

      split

      assert_file_contents <<-EOF
        foo(:one => 1,
            :two => 2)
      EOF

      join

      assert_file_contents <<-EOF
        foo(:one => 1, :two => 2)
      EOF
    end

    specify "doesn't get confused by interpolation" do
      vim.command('let g:splitjoin_ruby_curly_braces = 1')

      set_file_contents <<-EOF
        foo "\#{one}", :two => 3
      EOF

      vim.search 'foo'
      split

      assert_file_contents <<-EOF
        foo "\#{one}", {
          :two => 3,
        }
      EOF

      join

      assert_file_contents <<-EOF
        foo "\#{one}", { :two => 3 }
      EOF
    end
  end
end
