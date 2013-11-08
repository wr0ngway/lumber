require 'active_support/concern'

module Lumber

  # Include this module to add a logger accessible from both class and instance methods.
  # A logger hierarchy will be created if the class including this module is nested
  module PreventRailsOverride
    extend ActiveSupport::Concern

    included do

      class << self
        # Prevent rails from overwriting our logger
        def cattr_accessor_with_lumber(*syms)
          without_logger = syms.reject {|s| s == :logger}
          cattr_accessor_without_lumber(*without_logger)
        end
        alias_method_chain :cattr_accessor, :lumber
      end

    end

  end

end
