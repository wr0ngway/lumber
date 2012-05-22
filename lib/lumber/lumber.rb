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
  #
  # All config options get passed through to the log4r
  # configurator for use in defining outputters
  #
  def self.init(opts = {})
    opts[:root] ||= RAILS_ROOT.to_s if defined?(RAILS_ROOT)
    opts[:env] ||= RAILS_ENV if defined?(RAILS_ENV)
    opts[:config_file] ||= "#{opts[:root]}/config/log4r.yml"
    opts[:log_file] ||= "#{opts[:root]}/log/#{opts[:env]}.log"
    opts[:monitor_enabled] ||= true
    opts[:monitor_interval] ||= 60
    
    raise "Lumber.init missing one of :root, :env" unless opts[:root] && opts[:env]

    cfg = Log4r::YamlConfigurator
    opts.each do |k, v|
      cfg[k.to_s] = v.to_s
    end
    cfg['hostname'] = Socket.gethostname

    cfg.load_yaml_file(opts[:config_file])

    # Workaround for rails bug: http://dev.rubyonrails.org/ticket/8665
    if defined?(RAILS_DEFAULT_LOGGER)
      Object.send(:remove_const, :RAILS_DEFAULT_LOGGER)
    end
    Object.const_set('RAILS_DEFAULT_LOGGER', Log4r::Logger[BASE_LOGGER])

    @@registered_loggers = {}
    self.register_inheritance_handler()
    
    if opts[:monitor_store]
      LevelUtil.cache = opts[:monitor_store]
    elsif defined?(RAILS_CACHE)
      LevelUtil.cache = RAILS_CACHE
    end
    LevelUtil.start_monitor(opts[:monitor_interval]) if opts[:monitor_enabled]
  end

  def self.find_or_create_logger(fullname)
    Log4r::Logger[fullname] || Log4r::Logger.new(fullname)
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
  def self.setup_logger_hierarchy(class_name, class_logger_fullname)
    @@registered_loggers[class_name] = class_logger_fullname

    begin
      clazz = class_name.constantize

      # ActiveSupport 3.2 introduced class_attribute, which is supposed to be used instead of class_inheritable_accessor if available
      [:class_attribute, :class_inheritable_accessor].each do |class_attribute_method|

        if clazz.respond_to? class_attribute_method
          clazz.class_eval do
            send class_attribute_method, :logger
            self.logger = Lumber.find_or_create_logger(class_logger_fullname)
          end

          break
        end
      end

    rescue NameError
      # The class hasn't been defined yet.  No problem, we've registered the logger for when the class is created.
    end
  end

  private

  # Adds a inheritance handler to Object so we can know to add loggers
  # for classes as they get defined.
  def self.register_inheritance_handler()
    return if defined?(Object.inherited_with_lumber_log4r)

    Object.class_eval do

      class << self

        def inherited_with_lumber_log4r(subclass)
          inherited_without_lumber_log4r(subclass)

          # if the new class is in the list that were registered directly,
          # then create their logger attribute directly, otherwise derive it
          logger_name = @@registered_loggers[subclass.name]
          if logger_name
            Lumber.add_lumber_logger(subclass, logger_name)
          else
            Lumber.derive_lumber_logger(subclass)
          end
        end

        alias_method_chain :inherited, :lumber_log4r

      end

    end

  end

  def self.add_lumber_logger(clazz, logger_name)
    clazz.class_eval do
      # ActiveSupport 3.2 introduced class_attribute, which is supposed to be used instead of class_inheritable_accessor if available
      if respond_to? :class_attribute
        class_attribute :logger
      else
        class_inheritable_accessor :logger
      end

      self.logger = Lumber.find_or_create_logger(logger_name)

      class << self

        # Prevent rails from overwriting our logger
        def cattr_accessor_with_lumber_log4r(*syms)
          without_logger = syms.reject {|s| s == :logger}
          cattr_accessor_without_lumber_log4r(*without_logger)
        end
        alias_method_chain :cattr_accessor, :lumber_log4r

      end

    end
  end

  def self.derive_lumber_logger(clazz)
    # otherwise, walk up the classes hierarchy till you find a logger
    # that was registered, and use that logger as the parent for the
    # logger of the new class
    parent = clazz.superclass
    while ! parent.nil?
      parent_logger_name = parent.logger.fullname rescue ''
      parent_is_registered = @@registered_loggers.values.find {|v| parent_logger_name.index(v) == 0}
      if parent_is_registered && parent.method_defined?(:logger=)
        fullname = "#{parent_logger_name}::#{clazz.name.nil? ? 'anonymous' : clazz.name.split('::').last}"
        clazz.logger = Lumber.find_or_create_logger(fullname)
        break
      end
      parent = parent.superclass
    end
  end

end