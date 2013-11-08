$:.unshift(File.dirname(__FILE__))

# before config block
require "monitor"
require "lumber/lumber"
require "lumber/inheritance_registry"
require "lumber/logger_support"
require "lumber/prevent_rails_override"
require "lumber/log4r"
require "lumber/level_util"
require "lumber/json_formatter"


if defined?(Rails::Railtie)
  module Lumber
    require 'lumber/railtie'
  end
end
