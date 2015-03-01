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

  specify "if-clauses with comments" do
    set_file_contents <<-EOF
      if 6 * 9 == 42
        return "the answer" # comment
      end
    EOF

    vim.search 'if'
    join

    assert_file_contents <<-EOF
      # comment
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

    it "handles comments" do
      set_file_contents <<-EOF
        if condition
          'this' # comment
        else
          'that'
        end
      EOF

      join

      assert_file_contents <<-EOF
        # comment
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

  describe "when-then" do
    it "joins when-then" do
      set_file_contents <<-EOF
        when condition
          do_stuff
        when condition
      EOF

      join

      assert_file_contents <<-EOF
        when condition then do_stuff
        when condition
      EOF
    end

    it "splits when-then" do
      set_file_contents <<-EOF
        when condition then do_stuff
      EOF

      split

      assert_file_contents <<-EOF
        when condition
          do_stuff
      EOF
    end

    it "works only when there is one line in the then body" do
      set_file_contents <<-EOF
        when condition
          do_stuff
          do_something_else
      EOF

      join

      assert_file_contents <<-EOF
        when condition
          do_stuff
          do_something_else
      EOF
    end
  end

  describe 'cases' do
    it "joins cases with well formed when-thens" do
      set_file_contents <<-EOF
        case
        when condition1
          stuff1
        when condition2
          stuff2
        end
      EOF

      join

      assert_file_contents <<-EOF
        case
        when condition1 then stuff1
        when condition2 then stuff2
        end
      EOF
    end

    it "passes over ill formed when thens do" do
      set_file_contents <<-EOF
        case
        when condition1
          stuff1
        when condition2
          stuff2
          stuff3
        when condition 3
          stuff4
        end
      EOF

      join

      assert_file_contents <<-EOF
        case
        when condition1 then stuff1
        when condition2
          stuff2
          stuff3
        when condition 3 then stuff4
        end
      EOF
    end

    it "one-lines else as well" do
      set_file_contents <<-EOF
        case
        when condition1
          stuff1
        when condition2
          stuff2
        else
          stuff3
        end
      EOF

      join

      assert_file_contents <<-EOF
        case
        when condition1 then stuff1
        when condition2 then stuff2
        else stuff3
        end
      EOF
    end

    it "aligns thens in supercompact cases" do
      pending('we need to add an alignment tool to the spec configuration')

      set_file_contents <<-EOF
        case
        when cond1
          stuff1
        when condition2
          stuff2
        else
          stuff3
        end
      EOF

      join

      assert_file_contents <<-EOF
        case
        when cond1      then stuff1
        when condition2 then stuff2
        else stuff3
        end
      EOF
    end

    it "doesn't one line else when the case is not well formed" do
      set_file_contents <<-EOF
        case
        when condition1
          stuff1
        when condition2
          stuff2
          stuff3
        else
          stuff3
        end
      EOF

      join

      assert_file_contents <<-EOF
        case
        when condition1 then stuff1
        when condition2
          stuff2
          stuff3
        else
          stuff3
        end
      EOF
    end

    it "expands/split all one liners in a case" do
      set_file_contents <<-EOF
        case
        when condition1 then stuff1
        when condition2
          stuff2
        else stuff3
        end
      EOF

      split

      assert_file_contents <<-EOF
        case
        when condition1
          stuff1
        when condition2
          stuff2
        else
          stuff3
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
        :one => 'two'
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
    it "splitjoins {}-blocks prepended by ?" do
      set_file_contents <<-EOF
        pens.any?{ |pen| pen.name.to_sym.in? names.flatten }
      EOF

      vim.search('to_sym')
      split

      assert_file_contents <<-EOF
        pens.any? do |pen|
          pen.name.to_sym.in? names.flatten
        end
      EOF

      join

      assert_file_contents <<-EOF
        pens.any? { |pen| pen.name.to_sym.in? names.flatten }
      EOF
    end

    it "splitjoins {}-blocks prepended by !" do
      set_file_contents <<-EOF
        pens.find!{ |pen| pen.name.to_sym.in? names.flatten }
      EOF

      vim.search('to_sym')
      split

      assert_file_contents <<-EOF
        pens.find! do |pen|
          pen.name.to_sym.in? names.flatten
        end
      EOF

      join

      assert_file_contents <<-EOF
        pens.find! { |pen| pen.name.to_sym.in? names.flatten }
      EOF
    end

    it "splitjoins {}-blocks prepended by -> ()" do
      set_file_contents <<-EOF
        -> (pen){ |pen| pen.name.to_sym.in? names.flatten }
      EOF

      vim.search('to_sym')
      split

      assert_file_contents <<-EOF
       -> (pen) do |pen|
         pen.name.to_sym.in? names.flatten
       end
      EOF

      join

      assert_file_contents <<-EOF
        -> (pen) { |pen| pen.name.to_sym.in? names.flatten }
      EOF
    end

    it "splitjoins {}-blocks prepended by ->" do
      set_file_contents <<-EOF
        -> { |pen| pen.name.to_sym.in? names.flatten }
      EOF

      vim.search('to_sym')
      split

      assert_file_contents <<-EOF
       -> do |pen|
         pen.name.to_sym.in? names.flatten
       end
      EOF

      join

      assert_file_contents <<-EOF
        -> { |pen| pen.name.to_sym.in? names.flatten }
      EOF
    end

    it "splitjoins {}-blocks without leading whitespace" do
      set_file_contents <<-EOF
        Bar.new{ |b| puts b.to_s }
      EOF

      vim.search('puts')
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

    it "splitjoins {}-blocks with arguments and do-end blocks" do
      set_file_contents <<-EOF
        Bar.new { |b| puts b.to_s }
      EOF

      vim.search('puts')
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

    it 'splitjoins {}-blocks without arguments and do-end blocks' do
      set_file_contents <<-EOF
        this { block doesnt, get: mangled }
      EOF

      vim.search 'block'
      split

      assert_file_contents <<-EOF
        this do
          block doesnt, get: mangled
        end
      EOF

      join

      assert_file_contents <<-EOF
        this { block doesnt, get: mangled }
      EOF
    end

    it "optimizes particular cases to &-shorthands" do
      set_file_contents <<-EOF
        [1, 2, 3, 4].map(&:to_s)
      EOF

      vim.search 'to_s'
      split

      assert_file_contents <<-EOF
        [1, 2, 3, 4].map do |i|
          i.to_s
        end
      EOF

      set_file_contents <<-EOF
        [1, 2, 3, 4].map do |whatever|
          whatever.to_s
        end
      EOF

      vim.search 'whatever|'
      join

      assert_file_contents <<-EOF
        [1, 2, 3, 4].map(&:to_s)
      EOF
    end

    it "handles trailing code" do
      set_file_contents <<-EOF
        Bar.new { |one| two }.map(&:name)
      EOF

      vim.search 'one'
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

    it "migrates inline comments when joining" do
      set_file_contents <<-EOF
        foo do
          example # comment
        end
      EOF

      vim.search 'do'
      join

      assert_file_contents <<-EOF
        # comment
        foo { example }
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

  describe "method arguments" do
    specify "with hanging args" do
      vim.command('let g:splitjoin_ruby_hanging_args = 1')

      set_file_contents(<<-EOF)
        params.permit(:title, :action, :subject_type, :subject_id, :own)
      EOF

      vim.search(':title')
      split

      assert_file_contents(<<-EOF)
        params.permit(:title,
                      :action,
                      :subject_type,
                      :subject_id,
                      :own)
      EOF
    end

    specify "without hanging args" do
      vim.command('let g:splitjoin_ruby_hanging_args = 0')

      set_file_contents(<<-EOF)
        params.permit(:title, :action, :subject_type, :subject_id, :own)
      EOF

      vim.search(':title')
      split

      assert_file_contents(<<-EOF)
        params.permit(
          :title,
          :action,
          :subject_type,
          :subject_id,
          :own
        )
      EOF
    end

    specify "without brackets" do
      vim.command('let g:splitjoin_ruby_hanging_args = 0')

      set_file_contents(<<-EOF)
        params.permit :title, :action, :subject_type, :subject_id, :own
      EOF

      vim.search(':title')
      split

      assert_file_contents(<<-EOF)
        params.permit(
          :title,
          :action,
          :subject_type,
          :subject_id,
          :own
        )
      EOF
    end

    specify "with spaces around brackets" do
      vim.command('let g:splitjoin_ruby_hanging_args = 0')

      set_file_contents(<<-EOF)
        foo = bar( "one", "two" )
      EOF

      vim.search('one')
      split

      assert_file_contents(<<-EOF)
        foo = bar(
          "one",
          "two"
        )
      EOF
    end
  end

  describe "method options" do
    specify "with curly braces" do
      vim.command('let g:splitjoin_ruby_curly_braces = 1')

      set_file_contents <<-EOF
        foo 1, 2, :one => 1, :two => 2
      EOF

      vim.search(':one')
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

      vim.search(':one')
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

      vim.search 'one'
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

    specify "with arguments, round braces, curly braces" do
      vim.command('let g:splitjoin_ruby_curly_braces = 1')

      set_file_contents <<-EOF
        foo(one, :two => 2, :three => 3)
      EOF

      vim.search 'one'
      split

      assert_file_contents <<-EOF
        foo(one, {
          :two => 2,
          :three => 3,
        })
      EOF
    end

    specify "doesn't get confused by interpolation" do
      vim.command('let g:splitjoin_ruby_curly_braces = 1')

      set_file_contents <<-EOF
        foo "\#{one}", :two => 3
      EOF

      vim.search ':two'
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

  describe "array literals" do
    specify "simple case with {" do
      set_file_contents "array = %w{one two three}"

      vim.search 'one'
      split

      assert_file_contents <<-EOF
        array = %w{
          one
          two
          three
        }
      EOF

      vim.search '%w{'
      join

      assert_file_contents "array = %w{one two three}"
    end

    specify "simple case with |" do
      set_file_contents "array = %w|one two three|"

      vim.search 'one'
      split

      assert_file_contents <<-EOF
        array = %w|
          one
          two
          three
        |
      EOF

      vim.search '%w|'
      join

      assert_file_contents "array = %w|one two three|"
    end
  end
end
