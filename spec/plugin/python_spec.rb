require 'spec_helper'

describe "python" do
  let(:filename) { 'test.py' }

  before :each do
    vim.set(:expandtab)
    vim.set(:shiftwidth, 4)
  end

  specify "dictionaries" do
    set_file_contents "spam = {'spam': [1, 2, 3], 'spam, spam': 'eggs'}"

    vim.search '{'
    split

    assert_file_contents <<~EOF
      spam = {
              'spam': [1, 2, 3],
              'spam, spam': 'eggs'
              }
    EOF

    join

    assert_file_contents "spam = {'spam': [1, 2, 3], 'spam, spam': 'eggs'}"
  end

  specify "dictionaries with non-string keys" do
    set_file_contents "spam = {spam: [1, 2, 3], 'spam, spam': 'eggs'}"

    vim.search '{'
    split

    assert_file_contents <<~EOF
      spam = {
              spam: [1, 2, 3],
              'spam, spam': 'eggs'
              }
    EOF

    join

    assert_file_contents "spam = {spam: [1, 2, 3], 'spam, spam': 'eggs'}"
  end

  specify "lists" do
    set_file_contents 'spam = [1, [2, 3], 4]'

    vim.search '[1'
    split

    assert_file_contents <<~EOF
      spam = [1,
              [2, 3],
              4]
    EOF

    join

    assert_file_contents 'spam = [1, [2, 3], 4]'
  end

  specify "imports" do
    set_file_contents 'from foo import bar, baz'

    split

    assert_file_contents <<~EOF
      from foo import bar,\\
              baz
    EOF

    join
    assert_file_contents 'from foo import bar, baz'

    vim.command 'let b:splitjoin_python_import_style = "round_brackets"'
    split

    assert_file_contents <<~EOF
      from foo import (bar,
                       baz)
    EOF

    join
    assert_file_contents 'from foo import bar, baz'

    vim.command 'let b:splitjoin_python_brackets_on_separate_lines = 1'
    split

    assert_file_contents <<~EOF
      from foo import (
          bar,
          baz
      )
    EOF

    join
  end

  specify "statements" do
    set_file_contents 'while True: loop()'

    split

    assert_file_contents <<~EOF
      while True:
          loop()
    EOF

    join

    assert_file_contents 'while True: loop()'
  end

  specify "ternary clauses" do
    set_file_contents <<~EOF
      with indent as _:
          max_x = x1 if x1 > x2 else x2
    EOF

    vim.search('max_x')
    split

    assert_file_contents <<~EOF
      with indent as _:
          if x1 > x2:
              max_x = x1
          else:
              max_x = x2
    EOF

    join

    assert_file_contents <<~EOF
      with indent as _:
          max_x = x1 if x1 > x2 else x2
    EOF
  end

  specify "splitting within a string" do
    pending "Old version on CI" if ENV['CI']

    set_file_contents <<~EOF
      run("one", "two", "three {}".format(four))
    EOF

    vim.search('one')
    split

    assert_file_contents <<~EOF
      run("one",
          "two",
          "three {}".format(four))
    EOF
  end

  specify "chained method calls" do
    pending "Old version on CI" if ENV['CI']

    set_file_contents <<~EOF
      SomeModel.objects.filter(asdf=1, qwer=2).exclude(zxcv=2, tyui=3)
    EOF

    vim.search('zxcv')
    split

    assert_file_contents <<~EOF
      SomeModel.objects.filter(asdf=1, qwer=2).exclude(zxcv=2,
                                                       tyui=3)
    EOF
  end

  specify "variable assignment" do
    set_file_contents <<~EOF
      def example(self):
          one, self.two, three = foo("bar"), ["one", "two"], {foo: "bar"}
    EOF

    vim.search('two')
    split

    assert_file_contents <<~EOF
      def example(self):
          one = foo("bar")
          self.two = ["one", "two"]
          three = {foo: "bar"}
    EOF

    vim.search('two')
    join

    assert_file_contents <<~EOF
      def example(self):
          one = foo("bar")
          self.two, three = ["one", "two"], {foo: "bar"}
    EOF
  end

  specify "variable assignment of an array" do
    set_file_contents <<~EOF
      def example():
          one, two, three = Some.expression("that returns an array")
    EOF

    vim.search('two')
    split

    assert_file_contents <<~EOF
      def example():
          one = Some.expression("that returns an array")[0]
          two = Some.expression("that returns an array")[1]
          three = Some.expression("that returns an array")[2]
    EOF

    vim.search('one')
    join

    assert_file_contents <<~EOF
      def example():
          one, two, three = Some.expression("that returns an array")
    EOF
  end

  specify "dictionary within tuple" do
    pending "Old version on CI" if ENV['CI']

    set_file_contents <<~EOF
      out = ("one", {"two": "three"}, "four")
    EOF

    vim.search('one')
    split

    assert_file_contents <<~EOF
      out = ("one",
             {"two": "three"},
             "four")
    EOF

    vim.search('one')
    join

    assert_file_contents <<~EOF
      out = ("one", {"two": "three"}, "four")
    EOF
  end

  specify "tuple within dictionary" do
    set_file_contents <<~EOF
      out = {"one": "two", "key": ("three", "four")}
    EOF

    vim.search('one')
    split

    assert_file_contents <<~EOF
      out = {
              "one": "two",
              "key": ("three", "four")
              }
    EOF

    vim.search('out')
    join

    assert_file_contents <<~EOF
      out = {"one": "two", "key": ("three", "four")}
    EOF
  end

  specify "list comprehensions" do
    pending "Old version on CI" if ENV['CI']

    set_file_contents <<~EOF
      result = [x * y for x in range(1, 10) for y in range(10, 20) if x != y]
    EOF

    vim.search('x')
    split

    assert_file_contents <<~EOF
      result = [x * y
                for x in range(1, 10)
                for y in range(10, 20)
                if x != y]
    EOF

    vim.search('[')
    join

    assert_file_contents <<~EOF
      result = [x * y for x in range(1, 10) for y in range(10, 20) if x != y]
    EOF
  end

  describe "strings" do
    it "joins ''' strings into single-quoted strings" do
      set_file_contents <<~EOF
        string = '''
            something, "anything"
        '''
      EOF

      vim.search "'''"
      join

      assert_file_contents <<~EOF
        string = 'something, "anything"'
      EOF
    end

    it "joins \"\"\" strings into double-quoted strings" do
      set_file_contents <<~EOF
        string = """
            something, 'anything'
        """
      EOF

      vim.search '"""'
      join

      assert_file_contents <<~EOF
        string = "something, 'anything'"
      EOF
    end

    it "splits single-line \"\"\" strings" do
      set_file_contents <<~EOF
        string = """something, 'anything'"""
      EOF

      vim.search '"""'
      split

      assert_file_contents <<~EOF
        string = """
            something, 'anything'
        """
      EOF
    end

    it "splits single-line ''' strings" do
      set_file_contents <<~EOF
        string = '''something, "anything"'''
      EOF

      vim.search "'''"
      split

      assert_file_contents <<~EOF
        string = '''
            something, "anything"
        '''
      EOF
    end

    it "splits empty single-line ''' strings" do
      set_file_contents <<~EOF
        string = ''' '''
      EOF

      vim.search "'''"
      split

      assert_file_contents <<~EOF
        string = '''
        '''
      EOF
    end

    it "splits empty single-line \"\"\" strings" do
      set_file_contents <<~EOF
        string = """ """
      EOF

      vim.search '"""'
      split

      assert_file_contents <<~EOF
        string = """
        """
      EOF
    end

    it "doesn't split already-multiline \"\"\"-strings" do
      set_file_contents <<~EOF
        string = """
            something, 'anything'
        """
      EOF

      vim.search '"""'
      split

      assert_file_contents <<~EOF
        string = """
            something, 'anything'
        """
      EOF
    end

    it "doesn't split already-multiline '''-strings" do
      set_file_contents <<~EOF
        string = '''
            something, 'anything'
        '''
      EOF

      vim.search "'''"
      split

      assert_file_contents <<~EOF
        string = '''
            something, 'anything'
        '''
      EOF
    end

    it "splits normal strings into multiline strings" do
      set_file_contents 'string = "\"anything\""'

      vim.search '"\"'
      split

      assert_file_contents <<~EOF
        string = """
            "anything"
        """
      EOF
    end

    it "splits empty strings into empty multiline strings" do
      set_file_contents 'string = ""'

      vim.search '"'
      split

      assert_file_contents <<~EOF
        string = """
        """
      EOF
    end

    it "keeps content around the string, only splits with cursor on delimiter" do
      set_file_contents 'string = function_call(one, "two", three)'

      vim.search '"'
      split

      assert_file_contents <<~EOF
        string = function_call(one, """
            two
        """, three)
      EOF
    end
  end
end
