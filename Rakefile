require 'rake'
require 'rake/testtask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "defensio"
    gemspec.summary = "Official Ruby library for Defensio 2.0"
    gemspec.description = "Official Ruby library for Defensio 2.0"
    gemspec.email = "support@defensio.com"
    gemspec.homepage = "http://github.com/defensio/defensio-ruby"
    gemspec.authors = ["The Defensio Team", "Carl Mercier"]
    gemspec.add_dependency('httparty', '>= 0.5.0')
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install jeweler -s http://gemcutter.org"
end

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib' << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end
 
task :default => :test
