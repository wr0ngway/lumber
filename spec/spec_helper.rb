ENV['RACK_ENV'] = 'test'

# coveralls+rspec+java causes exit code of 1 even when specs pass
if ENV['CI'] && RUBY_ENGINE != 'jruby'
  require 'coveralls'
  Coveralls.wear!
end

require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'sinatra'
Sinatra::Base.set :environment, :test

require 'lumber'
require "lumber/server"
include Lumber

require 'capybara/rspec'
require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist

def clean_indent(str)
  first_indent = nil
  str.lines.collect do |line|
    if line =~ /\S/ # line has at least one non-whitespace character
      if first_indent.nil?
        line =~ /^(\s*)/
        first_indent = $1
      end
      line.slice!(0, first_indent.size)
      line
    else
      ""
    end
  end.join()
end

def new_class(class_name, super_class=nil, super_module=nil)
  s = "class #{class_name}"
  s << " < #{super_class}" if super_class
  s << "; end"

  s = "module #{super_module}; #{s}; end" if super_module

  eval s
end

def assert_valid_logger(class_name, logger_name)
  clazz = eval class_name
  clazz.should_not be_nil
  clazz.respond_to?(:logger).should be_truthy
  lgr = clazz.logger
  lgr.should be_an_instance_of(Log4r::Logger)
  lgr.fullname.should == logger_name
end

RSpec.configure do |config|
  config.mock_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
  config.before(:each) do
    Object.constants.grep(/^(Foo|Bar)/).each do |c|
      Object.send(:remove_const, c)
    end
  end
end
