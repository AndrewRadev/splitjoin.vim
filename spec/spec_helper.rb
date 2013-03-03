require 'vimrunner'
require 'vimrunner/testing'
require_relative './support/vim'

RSpec.configure do |config|
  config.include Vimrunner::Testing
  config.include Support::Vim

  # cd into a temporary directory for every example.
  config.around do |example|
    tmpdir(VIM) do
      def vim
        VIM
      end

      example.call
    end
  end

  config.before(:suite) do
    VIM = Vimrunner.start
    VIM.add_plugin(File.expand_path('.'), 'plugin/splitjoin.vim')
  end

  config.after(:suite) do
    VIM.kill
  end
end
