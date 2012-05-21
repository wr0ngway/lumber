ENV['RACK_ENV'] = 'test'
Bundler.require(:development, :test)
Sinatra::Base.set :environment, :test

require 'lumber'
require "lumber/server"
include Lumber

require 'capybara/rspec'
Capybara.javascript_driver = :webkit
