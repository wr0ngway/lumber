module Lumber

  # Include this module to add a logger accessible from both class and instance methods.
  # A logger heirarchy will be created if the class including this module is nested
  module LoggerSupport

    def self.included(receiver)
      Lumber.setup_logger_hierarchy(receiver.name, "#{Lumber::BASE_LOGGER}::#{receiver.name}")
    end

  end

end
