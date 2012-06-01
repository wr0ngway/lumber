require 'rails'

module Lumber

  class Railtie < Rails::Railtie
    
    config.lumber = ActiveSupport::OrderedOptions.new
        
    initializer "lumber.initialize_logger", :before => :initialize_logger do |app|
      if app.config.lumber.enabled
        opts = {:root => Rails.root.to_s, :env => Rails.env}.merge(app.config.lumber)
        Lumber.init(opts)
        unless opts[:disable_auto_loggers]
          Lumber.setup_logger_hierarchy("ActiveRecord::Base", "rails::models")
          Lumber.setup_logger_hierarchy("ActionController::Base", "rails::controllers")
          Lumber.setup_logger_hierarchy("ActionMailer::Base", "rails::mailers")      
        end
        app.config.logger = Log4r::Logger[Lumber::BASE_LOGGER]
        
        config_level = app.config.log_level
        if config_level.present?
          level_str = config_level.to_s.upcase
          level = Log4r::LNAMES.index(level_str)
          raise "Invalid log level: #{config_level}" unless level
          app.config.logger.level = level
        end
      end
    end
    
    initializer "lumber.initialize_cache", :after => :initialize_cache do |app|
      if app.config.lumber.enabled
        LevelUtil.cache_provider = Rails.cache unless config.lumber.monitor_store
      end
    end
    
  end

end
