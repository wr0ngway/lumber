require 'log4r'
require 'log4r/yamlconfigurator'
require 'log4r/outputter/datefileoutputter'
require 'active_support/core_ext/array.rb'
require 'active_support/core_ext/class/attribute_accessors.rb'

class Log4r::Logger
  # Set to false to disable the silencer
  cattr_accessor :silencer
  self.silencer = true

  # Silences the logger for the duration of the block.
  def silence(temporary_level = nil)
    temporary_level = Log4r::ERROR unless temporary_level
    if silencer
      begin
        old_logger_level, self.level = level, temporary_level
        yield self
      ensure
        self.level = old_logger_level
      end
    else
      yield self
    end
  end

  # Convenience method to use exception_logger plugin to save important exceptions
  def log_exception(exception, details = {})
    details = details.stringify_keys
    max = details.keys.max { |a,b| a.length <=> b.length }
    env = details.keys.sort.inject [] do |env, key|
      env << '* ' + ("%-*s: %s" % [max.length, key, details[key].to_s.strip])
    end

    details_str = env.join("\n")
    trace = exception.backtrace.join("\n")
    error("Exception '#{exception.class_name}', '#{exception.message}', details:\n#{details_str}\nBacktrace:\n#{trace}")
  end

end
