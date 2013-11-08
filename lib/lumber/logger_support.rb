require 'active_support/concern'
require 'active_support/core_ext/module/delegation'

module Lumber

  # Include this module to add a logger accessible from both class and instance methods.
  # A logger hierarchy will be created if the class including this module is nested
  module LoggerSupport
    extend ActiveSupport::Concern

    included do

      delegate :logger, :to => "self.class"

    end

    module ClassMethods

      def lumber_logger_name
        # Use the registered logger name if this class is in the registry
        logger_name = Lumber::InheritanceRegistry[self.name]
        if logger_name.nil?
          # if not, find the first registered logger name in the superclass chain, if any
          logger_name = Lumber::InheritanceRegistry.find_registered_logger(self.superclass)
          if logger_name.nil?
            # use self as name as we aren't inheriting
            logger_name = "#{Lumber::BASE_LOGGER}#{Log4r::Log4rConfig::LoggerPathDelimiter}#{self.name}"
          else
            # base name on inherited logger and self since we are inheriting
            # In log4r, a logger's parent is looked up from the name, and
            # Lumber.find_or_create_logger ensures that loggers are created for
            # all pieces of the name
            logger_name = "#{logger_name}#{Log4r::Log4rConfig::LoggerPathDelimiter}#{self.name}"
          end
        end
        logger_name
      end

      def logger
        @lumber_logger ||= Lumber.find_or_create_logger(lumber_logger_name)
      end

      def logger=(logger)
        @lumber_logger = logger
      end

    end

  end

end
