require "socket"

require "active_support/core_ext/string/inflections"

begin
  # rails(active_support) 2
  require "active_support/core_ext/duplicable"
rescue LoadError
  # rails(active_support) 3
  require "active_support/core_ext/object/duplicable"
end

begin
  # attempt to explicitly load ActiveSupport::Deprecation for rails 3.2 (needed for active_support/core_ext/module)
  # this doesn't appear to be necessary for earlier versions of rails (and may raise a LoadError)
  require "active_support/deprecation"
ensure
  require "active_support/core_ext/class"
  require "active_support/core_ext/module"
end


module Lumber

  # name of top level logger (can't be root as you can't have outputters on root)
  BASE_LOGGER= 'rails'

  extend MonitorMixin
  extend self

  # The logger concern (ActiveSupport::Concern) to include in each class.
  attr_accessor :logger_concern
  self.logger_concern = Lumber::LoggerSupport

  # Initializes log4r system.  Needs to happen in
  # config/environment.rb before Rails::Initializer.run
  #
  # Options:
  #
  # * :root - defaults to RAILS_ROOT if defined
  # * :env - defaults to RAILS_ENV if defined
  # * :config_file - defaults to <root>}/config/log4r.yml
  # * :log_file - defaults to <root>}/log/<env>.log
  # * :monitor_enabled - defaults to true
  # * :monitor_interval - defaults to 60
  # * :monitor_store - defaults to Rails.cache if defined, memory otherwise, see Lumber::LevelUtil::MemoryCacheProvider for interface
  # * :logger_concern - the logger concern to include, defaults to Lumber::LoggerConcern
  #
  # All config options get passed through to the log4r
  # configurator for use in defining outputters
  #
  def init(opts = {})
    opts[:root] ||= RAILS_ROOT.to_s if defined?(RAILS_ROOT)
    opts[:env] ||= RAILS_ENV if defined?(RAILS_ENV)
    opts[:config_file] ||= "#{opts[:root]}/config/log4r.yml"
    opts[:log_file] ||= "#{opts[:root]}/log/#{opts[:env]}.log"
    opts[:monitor_enabled] = true unless opts[:monitor_enabled] == false
    opts[:monitor_interval] ||= 60

    raise "Lumber.init missing one of :root, :env" unless opts[:root] && opts[:env]

    cfg = Log4r::YamlConfigurator
    opts.each do |k, v|
      cfg[k.to_s] = v.to_s
    end
    cfg['hostname'] = Socket.gethostname

    cfg.load_yaml_file(opts[:config_file])

    self.logger_concern = opts[:logger_concern] if opts[:logger_concern]

    # Workaround for rails bug: http://dev.rubyonrails.org/ticket/8665
    if defined?(RAILS_DEFAULT_LOGGER)
      Object.send(:remove_const, :RAILS_DEFAULT_LOGGER)
    end
    Object.const_set('RAILS_DEFAULT_LOGGER', find_or_create_logger(BASE_LOGGER))

    Lumber::InheritanceRegistry.clear

    if opts[:monitor_store]
      # Setting to Rails.cache handled by a post initialize_cache rails initializer
      # since Rails.cache is not available when lumber is initialized
      LevelUtil.cache_provider = opts[:monitor_store]
    end
    LevelUtil.start_monitor(opts[:monitor_interval]) if opts[:monitor_enabled]
  end

  def logger_name(clazz)
    # Use the registered logger name if this class is in the registry
    logger_name = Lumber::InheritanceRegistry[clazz.name]
    if logger_name.nil?
      # if not, find the first registered logger name in the superclass chain, if any
      logger_name = Lumber::InheritanceRegistry.find_registered_logger(clazz.superclass)
      if logger_name.nil?
        # use name from clazz as we aren't inheriting
        logger_name = "#{Lumber::BASE_LOGGER}#{Log4r::Log4rConfig::LoggerPathDelimiter}#{clazz.name}"
      else
        # base name on inherited logger and clazz since we are inheriting
        # In log4r, a logger's parent is looked up from the name, and
        # Lumber.find_or_create_logger ensures that loggers are created for
        # all pieces of the name
        logger_name = "#{logger_name}#{Log4r::Log4rConfig::LoggerPathDelimiter}#{clazz.name}"
      end
    end
    logger_name
  end

  def logger_for(clazz)
    synchronize do
      Lumber.find_or_create_logger(logger_name(clazz))
    end
  end

  def find_or_create_logger(fullname)
    synchronize do
      logger = Log4r::Logger[fullname]
      if logger.nil?
        # build the loggers from the lhs up to ensure the name based logger inheritance gets applied
        parts = fullname.split(Log4r::Log4rConfig::LoggerPathDelimiter)
        aggregate_name = nil
        parts.each do |part|
          if aggregate_name.nil?
            aggregate_name = part
          else
            aggregate_name = "#{aggregate_name}#{Log4r::Log4rConfig::LoggerPathDelimiter}#{part}"
          end
          logger = Log4r::Logger[aggregate_name] || Log4r::Logger.new(aggregate_name)
        end
      end
      logger
    end
  end

  # Makes :logger exist independently for subclasses and sets that logger
  # to one that inherits from base_class for each subclass as it is created.
  # This allows you to have a finer level of control over logging, for example,
  # put just a single class, or hierarchy of classes, into debug log level
  #
  # for example:
  #
  #   Lumber.setup_logger_hierarchy("ActiveRecord::Base", "rails::models")
  #
  # causes all models that get created to have a log4r logger named
  # "rails::models::<class_name>".  This class can individually be
  # put into debug log mode in production (see {log4r docs}[http://log4r.sourceforge.net/manual.html]), and log
  # output will include "<class_name>" on every log from this class
  # so that you can tell where a log statement came from
  #
  def setup_logger_hierarchy(class_name, class_logger_fullname)
    Lumber::InheritanceRegistry.register_inheritance_handler

    begin
      clazz = class_name.constantize
      clazz.send(:include, Lumber.logger_concern)
    rescue NameError
      # The class hasn't been defined yet.  No problem, we register
      # the logger for when the class is created below
    end

    # Don't register the class until after we see if it is already defined, that
    # way LoggerSupport gets included _after_ class is defined and overrides logger
    Lumber::InheritanceRegistry[class_name] = class_logger_fullname
  end

  # Helper to make it easier to log context through log4r.yml
  def format_mdc()
    ctx = Log4r::MDC.get_context.collect {|k, v| k.to_s + "=" + v.to_s }.join(" ")
    ctx.gsub!('%', '%%')
    return ctx
  end

end
