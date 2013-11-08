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


      def logger
        # This should probably be synchronized, but don't want to
        # incur the performance hit on such a heavily used method.
        # I think the worst case is that it'll just get assigned
        # multiple times, but it'll get the same reference because
        # Lumber.logger has a lock
        @lumber_logger ||= Lumber.logger_for(self)
      end

      def logger=(logger)
        @lumber_logger = logger
      end

    end

  end

end
