require 'active_support/concern'

module Lumber

  # Include this module to add a logger accessible from both class and instance methods.
  # A logger hierarchy will be created if the class including this module is nested
  module PreventRailsOverride
    extend ActiveSupport::Concern

    included do

      class << self
        # Prevent rails from overwriting our logger
        def cattr_reader_with_lumber(*syms)
          without_logger = syms.reject {|s| s == :logger}
          cattr_reader_without_lumber(*without_logger)
        end
        alias_method_chain :cattr_reader, :lumber

        def cattr_writer_with_lumber(*syms)
          without_logger = syms.reject {|s| s == :logger}
          cattr_writer_without_lumber(*without_logger)
        end
        alias_method_chain :cattr_writer, :lumber

        def mattr_reader_with_lumber(*syms)
          without_logger = syms.reject {|s| s == :logger}
          mattr_reader_without_lumber(*without_logger)
        end
        alias_method_chain :mattr_reader, :lumber

        def mattr_writer_with_lumber(*syms)
          without_logger = syms.reject {|s| s == :logger}
          mattr_writer_without_lumber(*without_logger)
        end
        alias_method_chain :mattr_writer, :lumber

      end

    end

  end

end
