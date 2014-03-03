# -*- encoding: utf-8 -*-
require File.expand_path('../lib/lumber/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Matt Conway"]
  gem.email         = ["matt@conwaysplace.com"]
  gem.description   = %q{Lumber tries to make it easy to use the more robust log4r logging system within your rails application.  To do this it sets up log4r configuration from a yml file, and provides utility methods for adding a :logger accessor to classes dynamicaly as they get created.}
  gem.summary       = %q{Lumber integrates the log4r logging system within your application.}
  gem.homepage      = "http://github.com/wr0ngway/lumber"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "lumber"
  gem.require_paths = ["lib"]
  gem.version       = Lumber::VERSION
  gem.license       = 'MIT'
  
  gem.add_dependency("log4r", "~> 1.1.10")
  gem.add_dependency("activesupport")
  gem.add_dependency("sinatra")
  
  gem.add_development_dependency("rake")
  gem.add_development_dependency("rspec")
  gem.add_development_dependency("rack-test")
  gem.add_development_dependency("capybara")
  gem.add_development_dependency("poltergeist")
  gem.add_development_dependency("awesome_print")
  gem.add_development_dependency("sinatra-contrib")
  gem.add_development_dependency("rails", "~> 4.0.3")
end
