Bundler.with_clean_env do

  gem 'lumber', :path => File.expand_path("../..", __FILE__)
  run "bundle install"

  generate(:lumber)
  environment 'config.lumber.enabled = true'
  environment 'config.lumber.log_level = ""'

  generate(:resource, "user", "name:string")
  generate(:mailer, "user_mailer")

end
