module Support
  module Vim
    def set_file_contents(string)
      string = normalize_string(string)
      File.open(filename, 'w') { |f| f.write(string) }
      VIM.edit filename
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
      string = normalize_string(string)
      IO.read(filename).strip.should eq string
    end

    private

    def normalize_string(string)
      whitespace = string.scan(/^\s*/).first
      string.split("\n").map { |line| line.gsub /^#{whitespace}/, '' }.join("\n").strip
    end
  end
end
