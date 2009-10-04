require 'fileutils'
require 'find'

class LumberGenerator < Rails::Generator::Base

  def manifest
    record do |m|
      m.file('log4r.yml', 'config/log4r.yml')
    end
  end

  protected

  def banner
    usage = "Usage: #{$0} lumber\n"
    usage << "    Install configuration files for lumber\n"
    return usage
  end
end
