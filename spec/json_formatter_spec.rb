require "spec_helper"

describe Lumber::JsonFormatter do

  context "log4r yaml configuration" do

    it "has default values without configuration" do
      yml = <<-EOF
        log4r_config:
          pre_config:
            root:
              level: 'DEBUG'
          loggers:
            - name: "mylogger"

          outputters:
            - type: StdoutOutputter
              name: stdout
              formatter:
                type: JsonFormatter
      EOF

      cfg = Log4r::YamlConfigurator
      cfg.load_yaml_string(yml)
      outputter = Log4r::Outputter['stdout']
      outputter.formatter.should_not be_nil
      outputter.formatter.should be_a_kind_of Lumber::JsonFormatter
    end

    it "can receive key_mapping configuration" do
      yml = <<-EOF
        log4r_config:
          pre_config:
            root:
              level: 'DEBUG'
          loggers:
            - name: "mylogger"

          outputters:
            - type: StdoutOutputter
              name: stdout
              formatter:
                type: JsonFormatter
                key_mapping:
                  level: severity
                  backtrace: exception.bt
      EOF

      cfg = Log4r::YamlConfigurator
      cfg.load_yaml_string(yml)
      outputter = Log4r::Outputter['stdout']
      outputter.formatter.should_not be_nil
      outputter.formatter.should be_a_kind_of Lumber::JsonFormatter
      outputter.formatter.instance_variable_get(:@key_mapping).should eq({'level' => ['severity'], 'backtrace' => ['exception', 'bt']})
    end

    it "can receive fields configuration" do
      yml = <<-'EOF'
        log4r_config:
          pre_config:
            root:
              level: 'DEBUG'
          loggers:
            - name: "mylogger"

          outputters:
            - type: StdoutOutputter
              name: stdout
              formatter:
                type: JsonFormatter
                fields:
                  version: 1
                  dynamic: "#{1+1}"
      EOF
      yml.should include('#{1+1}')
      cfg = Log4r::YamlConfigurator
      cfg.load_yaml_string(yml)
      outputter = Log4r::Outputter['stdout']
      outputter.formatter.should_not be_nil
      outputter.formatter.should be_a_kind_of Lumber::JsonFormatter
      outputter.formatter.instance_variable_get(:@fields).should eq({'version' => 1, 'dynamic' => '2'})
    end

    it "can receive date_pattern configuration" do
      yml = <<-'EOF'
        log4r_config:
          pre_config:
            root:
              level: 'DEBUG'
          loggers:
            - name: "mylogger"

          outputters:
            - type: StdoutOutputter
              name: stdout
              formatter:
                type: JsonFormatter
                date_pattern: "%M"
      EOF
      cfg = Log4r::YamlConfigurator
      cfg.load_yaml_string(yml)
      outputter = Log4r::Outputter['stdout']
      outputter.formatter.should_not be_nil
      outputter.formatter.should be_a_kind_of Lumber::JsonFormatter
      outputter.formatter.instance_variable_get(:@date_pattern).should == "%M"
    end

  end
  
  context "#assign_mapped_key" do
    
    it "handles no mapping" do
      formatter = Lumber::JsonFormatter.new()
      data = {}
      formatter.send(:assign_mapped_key, data, 'foo', 'bar')
      data['foo'].should == 'bar'
    end
    
    it "handles simple mapping" do
      formatter = Lumber::JsonFormatter.new('key_mapping' => {'foo' => 'baz'})
      data = {}
      formatter.send(:assign_mapped_key, data, 'foo', 'bar')
      data['foo'].should be_nil
      data['baz'].should == 'bar'
    end

    it "handles deep mapping" do
      formatter = Lumber::JsonFormatter.new('key_mapping' => {'foo' => 'baz.bum'})
      data = {}
      formatter.send(:assign_mapped_key, data, 'foo', 'bar')
      data['foo'].should be_nil
      data['baz'].should eq({'bum' => 'bar'})
    end

    it "handles overlapping deep mapping" do
      formatter = Lumber::JsonFormatter.new('key_mapping' => {'foo' => 'baz.bum', 'dum' => 'baz.derf'})
      data = {}
      formatter.send(:assign_mapped_key, data, 'foo', 'bar')
      formatter.send(:assign_mapped_key, data, 'dum', 'hum')
      data['foo'].should be_nil
      data['dum'].should be_nil
      data['baz'].should eq({'bum' => 'bar', 'derf' => 'hum'})
    end

  end
  
  context "log contents" do

    before(:each) do
      @logger = Lumber.find_or_create_logger('mylogger')
      @sio = StringIO.new
      @outputter = Log4r::IOOutputter.new("sbout", @sio)
      @formatter = Lumber::JsonFormatter.new
      @outputter.formatter = @formatter
      @logger.outputters.clear
      @logger.outputters << @outputter

      Log4r::GDC.set(nil)
      Log4r::NDC.clear
      Log4r::MDC.get_context.keys.each {|k| Log4r::MDC.remove(k) }
    end
    
    it "logs as json" do
      @logger.info("howdy")
      @sio.string.size.should be_present
      json = JSON.parse(@sio.string)
      json['logger'].should == 'mylogger'
      json['level'].should == 'info'
      json['message'].should == 'howdy'
      json['timestamp'].should be_present
    end
    
    it "logs as json with mapping" do
      @formatter = Lumber::JsonFormatter.new('key_mapping' => {'level' => 'severity'})
      @outputter.formatter = @formatter

      @logger.info("howdy")
      json = JSON.parse(@sio.string)
      json['level'].should be_nil
      json['severity'].should == 'info'
    end

    it "logs as json with fields" do
      @formatter = Lumber::JsonFormatter.new('fields' => {'version' => 1})
      @outputter.formatter = @formatter

      @logger.info("howdy")
      json = JSON.parse(@sio.string)
      json['message'].should == 'howdy'
      json['version'].should == 1
    end

    it "logs as json with date format" do
      now = Time.now
      Time.stub(:now).and_return(now)
      @formatter = Lumber::JsonFormatter.new('date_pattern' => "%s")
      @outputter.formatter = @formatter

      @logger.info("howdy")
      json = JSON.parse(@sio.string)
      json['timestamp'].should == now.to_i.to_s
    end

    it "logs exception as json" do
      ex = StandardError.new("mybad")
      raise ex rescue nil
      @logger.error(ex)
      json = JSON.parse(@sio.string)
      json['message'].should == 'Caught StandardError: mybad'
      json['level'].should == 'error'
      json['backtrace'].should =~  /json_formatter_spec.rb:\d+/
      json['file'].should =~ /^\/.*json_formatter_spec.rb$/
      json['line'].should > 0
    end
    
    it "doesn't set file/line/method by default" do
      @logger.fatal("no tracing")
      json = JSON.parse(@sio.string)
      json['file'].should be_nil
      json['line'].should be_nil
      json['method'].should be_nil
    end

    it "uses trace data if enabled" do
      @logger.trace = true
      @logger.fatal("no tracing")
      json = JSON.parse(@sio.string)
      json['file'].should =~ /^\/.*json_formatter_spec.rb$/
      json['line'].should > 0
      json['method'].should be_present
    end
    
    it "uses global log4r context if available" do
      Log4r::GDC.set("mygdc")
      @logger.info("context")
      json = JSON.parse(@sio.string)
      json['gdc'].should == '"mygdc"'
    end
    
    it "uses nested log4r context if available" do
      Log4r::NDC.push("myndc0")
      Log4r::NDC.push(99)
      @logger.info("context")
      json = JSON.parse(@sio.string)
      json['ndc'].should == ['"myndc0"', "99"]
    end
    
    it "uses mapped log4r context if available" do
      Log4r::MDC.put("foo", "mymdcfoo")
      Log4r::MDC.put("lucky", 7)
      Log4r::MDC.put("myclass", Object)
      @logger.info("context")
      json = JSON.parse(@sio.string)
      json['mdc'].should == {"foo" => '"mymdcfoo"', "lucky" => "7", "myclass" => "Object"}
    end

    it "handles failure inspecting log4r context" do
      o = Object.new
      o.stub(:inspect).and_raise("bad")
      Log4r::GDC.set(o)
      Log4r::NDC.push(o); Log4r::NDC.push(5)
      Log4r::MDC.put("obj", o); Log4r::MDC.put("foo", "bar")
      @logger.info("context")
      json = JSON.parse(@sio.string)
      json['gdc'].should be_nil
      json['ndc'].should == ["5"]
      json['mdc'].should == {"foo" => '"bar"'}
    end
  end

end
