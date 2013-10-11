require "log4r/formatter/formatter"
require 'json'

module Lumber

  class JsonFormatter < Log4r::BasicFormatter

    def initialize(hash={})
      mapping = hash['key_mapping'] || {}
      @key_mapping = Hash[mapping.collect {|k, v| [k.to_s, v.to_s.split('.')]}]

      @fields = {}
      fields = hash['fields'] || {}
      fields.each do |k, v|
        if v.kind_of? String
          @fields[k.to_s] = v.to_s.gsub(/#\{(.+)\}/) {|m| eval($1) }
        else
          @fields[k.to_s] = v
        end
      end

      @date_pattern = hash['date_pattern'] || '%H:%M:%S'
    end

    def format(logevent)
      data = @fields.dup

      assign_mapped_key(data, :timestamp, Time.now.strftime(@date_pattern))
      assign_mapped_key(data, :logger, logevent.fullname)
      assign_mapped_key(data, :level, Log4r::LNAMES[logevent.level].downcase)

      if logevent.data.kind_of? Exception
        message = "Caught #{logevent.data.class}"
        message << ": #{logevent.data.message}" if logevent.data.message
        assign_mapped_key(data, :message, message)
        assign_mapped_key(data, :exception, logevent.data.class.to_s)
        trace = logevent.data.backtrace if logevent.data.respond_to?(:backtrace)
        if trace
          assign_mapped_key(data, :backtrace, trace.join("\n\t"))
          assign_mapped_key(data, :file, trace[0].split(":")[0])
          assign_mapped_key(data, :line, trace[0].split(":")[1].to_i)
        end
      else
        assign_mapped_key(data, :message, format_object(logevent.data))
      end

      if logevent.tracer
        file, line, method = parse_caller(logevent.tracer[0])
        assign_mapped_key(data, :file, file)
        assign_mapped_key(data, :line, line)
        assign_mapped_key(data, :method, method)
      end

      gdc = Log4r::GDC.get
      if gdc && gdc != $0
        value = nil
        begin
          value = gdc.inspect
        rescue
        end
        assign_mapped_key(data, :gdc, value)
      end

      if Log4r::NDC.get_depth > 0
        value = []
        Log4r::NDC.clone_stack.each do |x|
          begin
            value << x.inspect
          rescue
          end
        end
        assign_mapped_key(data, :ndc, value)
      end

      mdc = Log4r::MDC.get_context
      if mdc && mdc.size > 0
        value = {}
        mdc.each do |k, v|
          begin
            value[k] = v.inspect
          rescue
          end
        end
        assign_mapped_key(data, :mdc, value)
      end

      "#{data.to_json}\n"
    end

    private

    def assign_mapped_key(data, key, value)
      return if value.nil? || (value.respond_to?(:size) && value.size == 0)
      key = key.to_s
      mapped_key = @key_mapping[key]
      if mapped_key.nil?
        data[key] = value
      else
        current = data
        mapped_key.each_with_index do |k, i|
          if mapped_key.size > i+1
            current[k] ||= {}
            current = current[k]
          else
            current[k] = value
          end
        end
      end
    end

    def parse_caller(line)
      if /^(.+?):(\d+)(?::in `(.*)')?/ =~ line
        file = Regexp.last_match[1]
        line = Regexp.last_match[2].to_i
        method = Regexp.last_match[3]
        [file, line, method]
      else
        []
      end
    end
  end

end

# Log4r yml config only looks for constants in Log4r namespace
Log4r::JsonFormatter = Lumber::JsonFormatter
