module Lumber
  module LevelUtil
    
    extend MonitorMixin

    LOG_LEVELS_KEY = "lumber:log_levels"
    
    class MemoryCacheProvider
      def initialize
        @cache = {}  
      end
      
      def read(key)
        @cache[key]
      end
      
      def write(key, value, options={})
        @cache[key] = value
      end
    end
    
    # where to persist the log level mappings
    @cache_provider = MemoryCacheProvider.new
    # time in seconds till the overrides expires
    @ttl = 3600

    attr_accessor :cache_provider, :ttl
    
    # Sets the logger level overrides into the cache_provider so that we can temporarily use
    # a lower level for specific loggers to aid in debugging
    #
    # @param [Hash] Logger fullname mapping to level name, e.g. {'rails::models::User' => 'DEBUG'}
    def set_levels(levels)
      backup_levels(levels.keys)
      @cache_provider.write(LOG_LEVELS_KEY, levels, :expire_in => @ttl)
    end
    
    def get_levels()
      @cache_provider.read(LOG_LEVELS_KEY) || {}
    end
    
    # Activates previously set logger level overrides.  Should be called 
    # at code entry points, e.g. an ApplicationController before_filter,
    # or Resque::Worker callback
    def activate_levels
      levels = get_levels
      if levels.size == 0
        restore_levels
      else
        levels.each do |name, level|
          logger = Lumber.find_or_create_logger(name)
          level_val = Log4r::LNAMES.index(level)
          logger.level = level_val if level_val
        end
      end
    end

    protected
    
    @original_levels = {}
    
    # Backs up original values of logger levels before we overwrite them
    # This is better in local memory since we shouldn't reset loggers that we haven't set
    # @param [Enumerable<String>] The logger names to backup
    def backup_levels(loggers)
      synchronize do
        loggers.each do |name|
          logger = Lumber.find_or_create_logger(name)
          # only store the old level if we haven't overriden it's logger yet
          @original_levels[name] ||= logger.level
        end
      end
    end
    
    # Restores original values of logger levels after expiration
    def restore_levels
      synchronize do
        @original_levels.each do |name, level|
          logger = Lumber.find_or_create_logger(name)
          logger.level = level
        end
        @original_levels.clear
      end
    end
  
    extend self

  end
end
