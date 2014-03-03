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
        app.config.logger = Lumber.find_or_create_logger(Lumber::BASE_LOGGER)

        # backwards compat for setting log_level to '' to defer to log4r.yml
        # log_level needs to be set for rails >= 4.0.2
        if app.config.log_level.blank?
          app.config.log_level = Log4r::LNAMES[app.config.logger.level]
        end
      end
    end

    initializer "lumber.set_logger_level", :after => :initialize_logger do |app|
      if app.config.lumber.enabled
        # Set the level on logger to workaround rails forcing level
        # to a ::Logger constant in the :initialize_logger initializer
        # https://github.com/rails/rails/issues/13421
        config_level = app.config.log_level
        level_str = config_level.to_s.upcase
        level = Log4r::LNAMES.index(level_str)
        raise "Invalid log level: #{config_level}" unless level
        app.config.logger.level = level
      end
    end

    initializer "lumber.initialize_cache", :after => :initialize_cache do |app|
      # Only set the cache to Rails.cache if the user hasn't
      # specified a different monitor_store
      if app.config.lumber.enabled && ! app.config.lumber.monitor_store
        if defined?(Rails) && Rails.respond_to?(:cache)
          LevelUtil.cache_provider = Rails.cache
        elsif defined?(RAILS_CACHE)
          LevelUtil.cache_provider = RAILS_CACHE
        end
      end
    end

  end

end
