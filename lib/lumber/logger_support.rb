module Lumber

  # Include this module to add a logger accessible from both class and instance methods.
  # A logger heirarchy will be created if the class including this module is nested
  module LoggerSupport

    def self.included(receiver)
      receiver.class_eval do
        class_inheritable_accessor :logger
        last_logger = nil
        name_parts = self.name.split("::")
        name_parts.insert(0, Lumber::BASE_LOGGER)
        name_parts.each_with_index do |part, i|
          partial = name_parts[0..i].join("::")
          last_logger = Log4r::Logger[partial]
          if ! last_logger
            last_logger = Log4r::Logger.new(partial)
          end
        end
        self.logger = last_logger
      end
    end

  end
  
end
