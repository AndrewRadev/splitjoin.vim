Given /^the splitjoin plugin is loaded$/ do
  plugin_dir = File.expand_path('../../..', __FILE__)
  puts @vim.add_plugin plugin_dir, 'plugin/splitjoin.vim'
end

When /^I split the line$/ do
  @vim.command 'SplitjoinSplit'
end

When /^I pry$/ do
  require 'pry'
  pry
end
