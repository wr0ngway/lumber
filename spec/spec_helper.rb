ENV['RACK_ENV'] = 'test'

if ENV['CI']
  require 'coveralls'
  Coveralls.wear!
end

Bundler.require(:development, :test)
Sinatra::Base.set :environment, :test

require 'lumber'
require "lumber/server"
include Lumber

require 'capybara/rspec'
require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist
