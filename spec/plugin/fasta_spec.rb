require 'spec_helper'

describe "fasta" do
  let(:filename) { 'test.fasta' }

  specify "sequences" do
    set_file_contents <<~EOF
      >Something else
      ELVIS-LIVES
      > E.coli_K12 Cysteine--tRNA ligase
      MLKIFNTLTRQKEEFKPIHAGEVGMYVCGITVYDLCHIGHGRTFVAFDVVARYLRFLGYKLKYVRNITDIDDK...
      > Another one
      LIVES-ELVIS*
    EOF

    vim.set :filetype, 'fasta'
    vim.set :textwidth, 50

    vim.search '> E\.coli'
    split

    assert_file_contents <<~EOF
      >Something else
      ELVIS-LIVES
      > E.coli_K12 Cysteine--tRNA ligase
      MLKIFNTLTRQKEEFKPIHAGEVGMYVCGITVYDLCHIGHGRTFVAFDVV
      ARYLRFLGYKLKYVRNITDIDDK...
      > Another one
      LIVES-ELVIS*
    EOF

    join

    assert_file_contents <<~EOF
      >Something else
      ELVIS-LIVES
      > E.coli_K12 Cysteine--tRNA ligase
      MLKIFNTLTRQKEEFKPIHAGEVGMYVCGITVYDLCHIGHGRTFVAFDVVARYLRFLGYKLKYVRNITDIDDK...
      > Another one
      LIVES-ELVIS*
    EOF
  end
end
