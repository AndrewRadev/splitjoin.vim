require 'spec_helper'

describe "tex" do
  let(:filename) { 'test.latex' }

  before :each do
    vim.set :expandtab
    vim.set :shiftwidth, 2
  end

  describe "commands" do
    specify "simple commands" do
      set_file_contents <<~EOF
        \\caption{Example figure}
      EOF

      vim.search '{'
      split

      assert_file_contents <<~EOF
        \\caption{
          Example figure
        }
      EOF

      join

      assert_file_contents <<~EOF
        \\caption{Example figure}
      EOF
    end

    specify "nested escaped brackets" do
      set_file_contents <<~EOF
        \\caption{Example \\{nested\\} figure}
      EOF

      vim.search 'nested'
      split

      assert_file_contents <<~EOF
        \\caption{
          Example \\{nested\\} figure
        }
      EOF

      join

      assert_file_contents <<~EOF
        \\caption{Example \\{nested\\} figure}
      EOF
    end

    specify "with cursor on command" do
      set_file_contents <<~EOF
        \\caption{Example figure}
      EOF

      vim.search 'caption'
      split

      assert_file_contents <<~EOF
        \\caption{
          Example figure
        }
      EOF

      vim.search 'caption'
      join

      assert_file_contents <<~EOF
        \\caption{Example figure}
      EOF
    end
  end

  describe "blocks" do
    specify "simple blocks" do
      set_file_contents <<~EOF
        \\begin{center} Hello World \\end{center}
      EOF

      split

      assert_file_contents <<~EOF
        \\begin{center}
          Hello World
        \\end{center}
      EOF

      vim.search 'begin'
      join

      assert_file_contents <<~EOF
        \\begin{center} Hello World \\end{center}
      EOF
    end

    specify "multiline block" do
      set_file_contents <<~EOF
        \\begin{center} x = y\\\\  y = z \\end{center}
      EOF

      split

      assert_file_contents <<~EOF
        \\begin{center}
          x = y\\\\
          y = z
        \\end{center}
      EOF

      join

      assert_file_contents <<~EOF
        \\begin{center} x = y\\\\ y = z \\end{center}
      EOF
    end

    specify "block with parameters" do
      set_file_contents <<~EOF
        \\begin{tabular}[]{cc} row1 \\\\ row2 \\end{tabular}
      EOF

      split

      assert_file_contents <<~EOF
        \\begin{tabular}[]{cc}
          row1 \\\\
          row2
        \\end{tabular}
      EOF

      join

      assert_file_contents <<~EOF
        \\begin{tabular}[]{cc} row1 \\\\ row2 \\end{tabular}
      EOF
    end

    specify "itemized blocks" do
      set_file_contents <<~EOF
        \\begin{enumerate}\\item item1 \\item item2\\end{enumerate}
      EOF

      split

      assert_file_contents <<~EOF
        \\begin{enumerate}
          \\item item1
          \\item item2
        \\end{enumerate}
      EOF

      join

      assert_file_contents <<~EOF
        \\begin{enumerate} \\item item1 \\item item2 \\end{enumerate}
      EOF
    end
  end
end
