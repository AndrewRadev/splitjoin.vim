guard 'rspec', cmd: 'bundle exec rspec' do
  watch(%r{autoload/sj/(.*)\.vim}) { |m| "spec/plugin/#{m[1]}_spec.rb"}
end
