require "socket"

module Lumber

  # Initializes log4r system.  Needs to happen in
  # config/environment.rb before Rails::Initializer.run
  #
  # Options:
  #
  # * :root - defaults to RAILS_ROOT if defined
  # * :env - defaults to RAILS_ENV if defined
  # * :config_file - defaults to <root>}/config/log4r.yml
  # * :log_file - defaults to <root>}/log/<env>.log
  #
  # All config options get passed through to the log4r
  # configurator for use in defining outputters
  #
  def self.init(opts = {})
    opts[:root] ||= RAILS_ROOT if defined?(RAILS_ROOT)
    opts[:env] ||= RAILS_ENV if defined?(RAILS_ENV)
    opts[:config_file] ||= "#{opts[:root]}/config/log4r.yml"
    opts[:log_file] ||= "#{opts[:root]}/log/#{opts[:env]}.log"
    raise "Lumber.init missing one of :root, :env" unless opts[:root] && opts[:env]

    cfg = Log4r::YamlConfigurator
    opts.each do |k, v|
      cfg[k.to_s] = v
    end
    cfg['hostname'] = Socket.gethostname

    cfg.load_yaml_file(opts[:config_file])

    # Workaround for rails bug: http://dev.rubyonrails.org/ticket/8665
    if defined?(RAILS_DEFAULT_LOGGER)
      Object.send(:remove_const, :RAILS_DEFAULT_LOGGER)
    end
    Object.const_set('RAILS_DEFAULT_LOGGER', Log4r::Logger['rails'])

  end

  # Makes :logger exist independently for subclasses and sets that logger
  # to one that inherits from base_class for each subclass as its created.
  # This allows you to have a finer level of control over logging, for example,
  # put just a single class, or hierarchy of classes, into debug log level
  #
  # for example:
  #
  #   Lumber.setup_logger_hierarchy(ActiveRecord::Base, "rails::models")
  #
  # causes all models that get created to have a log4r logger named
  # "rails::models::<class_name>".  This class can individually be
  # put into debug log mode in production (see {log4r docs}[http://log4r.sourceforge.net/manual.html]), and log
  # output will include "<class_name>" on every log from this class
  # so that you can tell where a log statement came from
  #
  def self.setup_logger_hierarchy(base_class, parent_fullname)
    base_class.class_eval do
      class_inheritable_accessor :logger
      self.logger = Log4r::Logger.new(parent_fullname)

      class << self
        def inherited_with_lumber_log4r(subclass)
          inherited_without_lumber_log4r(subclass)
          # p "#{self} -> #{subclass} -> #{self.logger}"

          # Look up the class hierarchy for a useable logger
          # A class may have a nil logger if it was created
          # before we add logger/inheritance to its superclas,
          # e.g. Object/Exception - something tries to subclass
          # Exception after we added lumber_inherited to Object,
          # but Exception was defined before we added lumber_inherited 
          while self.logger.nil?
            next_class = (next_class ||self).superclass
            if next_class.nil?
              self.logger = Log4r::Logger.root
            else
              self.logger = next_class.logger
            end
          end
          subclass.logger = Log4r::Logger.new("#{logger.fullname}::#{subclass.name}")
        end
        alias_method_chain :inherited, :lumber_log4r
      end

    end
  end

end