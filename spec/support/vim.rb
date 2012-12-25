module Support
  module Vim
    def set_file_contents(string)
      write_file(filename, string)
      VIM.edit(filename)
    end

    def split
      VIM.command 'SplitjoinSplit'
      VIM.write
    end

    def join
      VIM.command 'SplitjoinJoin'
      VIM.write
    end

    def assert_file_contents(string)
      string = normalize_string_indent(string)
      IO.read(filename).strip.should eq string
    end
  end
end
