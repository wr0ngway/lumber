require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "lumber"
    gem.summary = %Q{Lumber integrates the log4r logging system within your application.}
    gem.description = %Q{Lumber tries to make it easy to use the more robust log4r logging system within your rails application.  To do this it sets up log4r configuration from a yml file, and provides utility methods for adding a :logger accessor to classes dynamicaly as they get created.}
    gem.email = "matt@conwaysplace.com"
    gem.homepage = "http://github.com/wr0ngway/lumber"
    gem.authors = ["Matt Conway"]
    gem.add_development_dependency "thoughtbot-shoulda"
    gem.add_dependency "log4r"
    gem.files =  FileList["[A-Z][A-Z]*", "{generators,lib}/**/*"]
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "lumber #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
