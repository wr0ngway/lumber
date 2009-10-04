require 'fileutils'
require 'find'

class LumberGenerator < Rails::Generator::NamedBase

  TEMPLATE_ROOT = File.dirname(__FILE__) + "/templates"
  TEMPLATE_FILE = "templates.yml"

  def manifest
    record do |m|
      m.file('log4r.xml', 'config')
    end
  end

  protected

    def banner
      usage = "Usage: #{$0} lumber\n"
        usage << "    Install config files needed to configure lumber\n"
      end
      return usage
    end
end
