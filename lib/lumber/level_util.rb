module Lumber
  module LevelUtil
    
    # So we have a named thread and can tell which we are in Thread.list
    class MonitorThread < Thread
      attr_accessor :exit
    end

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
    
    # @return [MemoryCacheProvider] Where to persist the log level mappings (Rails.cache interface), defaults to Memory
    attr_accessor :cache_provider
    @cache_provider = MemoryCacheProvider.new
    
    # @return [Integer] The time in seconds till the overrides expires, defaults to 3600
    attr_accessor :ttl
    @ttl = 3600
    
    # Sets the logger level overrides into the cache_provider so that we can temporarily use
    # a lower level for specific loggers to aid in debugging
    #
    # @param [Hash] Logger fullname mapping to level name, e.g. {'rails::models::User' => 'DEBUG'}
    #
    def set_levels(levels)
      levels = expand_heirarchy(levels)
      @cache_provider.write(LOG_LEVELS_KEY, levels, :expires_in => @ttl)
    end
    
    def get_levels()
      @cache_provider.read(LOG_LEVELS_KEY) || {}
    end
    
    # Activates previously set logger level overrides.  Should be called 
    # at code entry points, e.g. an ApplicationController before_filter,
    # or Resque::Worker callback
    #
    def activate_levels
      levels = get_levels
      if levels.size == 0
        restore_levels
      else
        
        levels = expand_heirarchy(levels)
        backup_levels(levels.keys)
        
        levels.each do |name, level|
          level_val = Log4r::LNAMES.index(level)
          outputter = Log4r::Outputter[name]
          if outputter
            outputter.level = level_val if level_val && outputter.level != level_val
          else
            logger = Lumber.find_or_create_logger(name)
            logger.level = level_val if level_val && logger.level != level_val
          end
        end
      end
    end

    # Convenience method for starting a thread to watch for changes in log
    # levels and apply them.  You don't need to use this if you are manually
    # calling activate levels at all your entry points.
    #
    # @param [Integer] How long to sleep between checks
    # @return [Thread] The monitor thread
    #
    def start_monitor(interval=10)
      t = MonitorThread.new do
        loop do
          break if self.exit

          begin
            activate_levels
          rescue => e
            $stderr.puts "Failure activating log levels: #{e}"
          end
          sleep interval
        end
      end

      at_exit { t.exit = true }

      t
    end
    
    protected
    
    @original_levels = {}
    @original_outputter_levels = {}
    
    # Backs up original values of logger levels before we overwrite them
    # This is better in local memory since we shouldn't reset loggers that we haven't set
    # @param [Enumerable<String>] The logger names to backup
    def backup_levels(loggers)
      synchronize do
        loggers.each do |name|
          outputter = Log4r::Outputter[name]
          if outputter
            @original_outputter_levels[name] ||= outputter.level
          else
            logger = Lumber.find_or_create_logger(name)
            # only store the old level if we haven't overriden it's logger yet
            @original_levels[name] ||= logger.level
          end
        end
      end
    end
    
    # Restores original values of logger levels after expiration
    def restore_levels
      synchronize do
        @original_outputter_levels.each do |name, level|
          outputter = Log4r::Outputter[name]
          outputter.level = level if outputter.level != level
        end
        @original_outputter_levels.clear
        
        @original_levels.each do |name, level|
          logger = Lumber.find_or_create_logger(name)
          logger.level = level if logger.level != level
        end
        @original_levels.clear
      end
    end
  
    # walk the logger heirarchy and add all parents and outputters to levels
    # so that the desired level of the child will take effect.  Doesn't override
    # any logger/levels that already have a value
    def expand_heirarchy(levels)
      result = levels.clone
      
      levels.each do |name, level|
        # only need to expand on loggers since outputter already in list
        if  Log4r::Outputter[name].nil?
          logger = Lumber.find_or_create_logger(name)
          while logger
            logger_name = logger.fullname
            break if logger_name.nil?
            result[logger_name] ||= level
            logger.outputters.each do |o|
              result[o.name] ||= level
            end
            logger = logger.parent
          end
        end
      end
      
      return result
    end
        
    extend self

  end
end
