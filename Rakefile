require 'rake'
require 'rake/testtask'
 
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib' << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end
 
task :default => :test

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "defensio"
    gemspec.summary = "Official Ruby library for Defensio 2.0"
    gemspec.email = "support@defensio.com"
    gemspec.homepage = "http://github.com/defensio/defensio-ruby"
    gemspec.description = "Official Ruby library for Defensio 2.0"
    gemspec.authors = ["Carl Mercier"]
    gemspec.files =  FileList["[A-Z]*", "defensio.rb", "{bin,generators,lib,test}/**/*"]
    gemspec.rubyforge_project = 'defensio'
    gemspec.add_dependency('patron', '>= 0.4.4')
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

begin
  require 'rake/contrib/sshpublisher'
  namespace :rubyforge do

    desc "Release gem and RDoc documentation to RubyForge"
    task :release => ["rubyforge:release:gem", "rubyforge:release:docs"]

    namespace :release do
      desc "Publish RDoc to RubyForge."
      task :docs => [:rdoc] do
        config = YAML.load(
            File.read(File.expand_path('~/.rubyforge/user-config.yml'))
        )

        host = "#{config['username']}@rubyforge.org"
        remote_dir = "/var/www/defensio/defensio/"
        local_dir = 'rdoc'

        Rake::SshDirPublisher.new(host, remote_dir, local_dir).upload
      end
    end
  end
rescue LoadError
  puts "Rake SshDirPublisher is unavailable or your rubyforge environment is not configured."
end