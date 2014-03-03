require 'spec_helper.rb'

describe Lumber::LoggerSupport do

  before(:each) do
    root = "#{File.dirname(__FILE__)}/.."
    Lumber.init(:root => root,
                :env => 'test',
                :config_file => "#{root}/lib/generators/lumber/templates/log4r.yml",
                :log_file => "/tmp/lumber-test.log")
  end

  it "should memoize logger" do
    class Foo; include Lumber::LoggerSupport; end
    Lumber.should_receive(:logger_for).once.and_call_original

    Foo.logger.fullname.should == "rails::Foo"
    Foo.logger.fullname.should == "rails::Foo"
  end

  it "makes a logger available for subclasses" do
    class Foo; include Lumber::LoggerSupport; end
    class Bar < Foo; end;
    Foo.logger.fullname.should == "rails::Foo"
    Bar.logger.fullname.should == "rails::Bar"
    Bar.logger.parent.fullname.should == "rails"
  end

  it "should have a logger instance accessible from an instance method" do
    class Foo; include Lumber::LoggerSupport; def member_method; logger.debug('hi'); end; end
    logger = Lumber.find_or_create_logger("rails::Foo")
    logger.should_receive(:debug).with('hi')
    Foo.new.member_method
  end

  it "should have a logger instance accessible from a class method " do
    class Foo; include Lumber::LoggerSupport; def self.class_method; logger.debug('hi'); end; end
    logger = Lumber.find_or_create_logger("rails::Foo")
    logger.should_receive(:debug).with('hi')
    Foo.class_method
  end

  it "should allow configuration of levels from yml" do
    yml = <<-EOF
      log4r_config:
        pre_config:
          root:
            level: 'DEBUG'
        loggers:
          - name: "rails::Foo"
            level: WARN
        outputters: []
    EOF
    
    cfg = Log4r::YamlConfigurator
    cfg.load_yaml_string(clean_indent(yml))
    logger = Lumber.find_or_create_logger("rails::Foo")
    sio = StringIO.new 
    logger.outputters = [Log4r::IOOutputter.new("sbout", sio)]
    class Foo; include Lumber::LoggerSupport; end
    
    Foo.logger.debug("noshow")
    Foo.logger.warn("yesshow")
    sio.string.should =~ /yesshow/
    sio.string.should_not =~ /noshow/
  end
    
end
