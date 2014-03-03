require 'active_support/concern'
require 'active_support/core_ext/module/delegation'

module Lumber

  # Include this module to add a logger accessible from both class and instance methods.
  # A logger hierarchy will be created if the class including this module is nested
  module LoggerSupport
    extend ActiveSupport::Concern

    included do

      delegate :logger, :to => "self.class"

      # put logger on singleton class so it overrides any already there,
      # and makes logger available from class, singleton_class and the
      # instance (from the delegate call)
      class << self

        def lumber_logger
          # This should probably be synchronized, but don't want to
          # incur the performance hit on such a heavily used method.
          # I think the worst case is that it'll just get assigned
          # multiple times, but it'll get the same reference because
          # Lumber.logger has a lock
          @lumber_logger ||= Lumber.logger_for(self)
        end

        def lumber_logger=(logger)
          @lumber_logger = logger
        end

        alias_method :logger, :lumber_logger

        # prevent rails from setting logger (e.g. when initializing ActionController::Base)
        def logger=(logger)
          logger.debug "lumber preventing set of logger for #{self} to #{logger}, use #lumber_logger= if you really want it set"
        end
      end

    end

  end

end
