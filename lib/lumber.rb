$:.unshift(File.dirname(__FILE__))

# before config block
require "lumber/lumber"
require "lumber/logger_support"
require "lumber/log4r"
require "lumber/level_util"
require "lumber/json_formatter"


if defined?(Rails::Railtie)
  module Lumber
    require 'lumber/railtie'
  end
end
