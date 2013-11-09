
class LumberGenerator < Rails::Generators::Base
  source_root File.expand_path("../templates", __FILE__)

  desc "This generator adds a log4r.yml in config/"
  def create_log4r_yml
    copy_file "log4r.yml", "config/log4r.yml"
  end

end
