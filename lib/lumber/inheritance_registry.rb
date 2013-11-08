module Lumber

  module InheritanceRegistry
    extend self

    @mapping = {}

    def []=(class_name, logger_fullname)
      @mapping[class_name] = logger_fullname
    end

    def [](class_name)
      @mapping[class_name]
    end

    def clear
      @mapping.clear
    end

    def find_registered_logger(clazz)
      return nil unless clazz
      logger_name = self[clazz.name]
      logger_name || find_registered_logger(clazz.superclass)
    end

    def remove_inheritance_handler
      return if ! defined?(Object.singleton_class.inherited_with_lumber_registry)

      Object.class_eval do
        class << self
          remove_method :inherited_with_lumber_registry
          remove_method :inherited
          alias_method :inherited, :inherited_without_lumber_registry
        end
      end
    end

    # Adds a inheritance handler to Object so we can add loggers for registered classes
    def register_inheritance_handler
      return if defined?(Object.singleton_class.inherited_with_lumber_registry)

      Object.class_eval do

        class << self

          def inherited_with_lumber_registry(subclass)
            inherited_without_lumber_registry(subclass)

            # Add a logger to 'subclass' if it is directly in the registry
            # No need to check full inheritance chain LoggerSupport handles it
            # Also prevent rails from subsequently overriding our logger when rails
            # is loaded after registering logger inheritance
            if Lumber::InheritanceRegistry[subclass.name]
              subclass.send(:include, Lumber::LoggerSupport)
              subclass.send(:include, Lumber::PreventRailsOverride)
            end
          end

          alias_method_chain :inherited, :lumber_registry

        end

      end

    end

  end

end