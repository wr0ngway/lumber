require 'spec_helper'
require 'delegate'

describe Lumber do

  before(:each) do
    root = "#{File.dirname(__FILE__)}/.."
    Lumber.init(:root => root,
                :env => 'test',
                :config_file => "#{root}/generators/lumber/templates/log4r.yml",
                :log_file => "/tmp/lumber-test.log")
  end

  describe "#logger_name" do

    it "generates a name for a simple class" do
      new_class('Foo')
      Lumber.logger_name(Foo).should == "rails::Foo"
    end

    it "generates a name for a registered class" do
      Lumber.setup_logger_hierarchy("Foo", "root::foo")
      new_class('Foo')
      Lumber.logger_name(Foo).should == "root::foo"
    end

    it "generates a name for a subclass" do
      Lumber.setup_logger_hierarchy("Foo", "root::foo")
      new_class('Foo')
      new_class('Bar', 'Foo')
      Lumber.logger_name(Bar).should == "root::foo::Bar"
    end

    it "generates a name for a deep subclass" do
      Lumber.setup_logger_hierarchy("Foo", "root::foo")
      new_class('Foo')
      new_class('Foo1', 'Foo')
      new_class('Bar', 'Foo1')
      Lumber.logger_name(Bar).should == "root::foo::Bar"
    end

  end

  describe "#logger_for" do

     it "gets the logger" do
       new_class('Foo')
       Lumber.logger_for(Foo).fullname.should == "rails::Foo"
     end

  end

  describe "#find_or_create_logger" do

    it "creates loggers for each segment" do
      Log4r::Logger['foo1'].should be_nil
      Log4r::Logger['foo1::foo2'].should be_nil
      Log4r::Logger['foo1::foo2::foo3'].should be_nil
      Log4r::Logger['foo1::foo2::foo3::bar'].should be_nil

      Lumber.find_or_create_logger("foo1::foo2::foo3::bar")

      Log4r::Logger['foo1'].should_not be_nil
      Log4r::Logger['foo1'].parent.should == Log4r::Logger['root']
      Log4r::Logger['foo1::foo2'].should_not be_nil
      Log4r::Logger['foo1::foo2'].parent.should == Log4r::Logger['foo1']
      Log4r::Logger['foo1::foo2::foo3'].should_not be_nil
      Log4r::Logger['foo1::foo2::foo3'].parent.should == Log4r::Logger['foo1::foo2']
      Log4r::Logger['foo1::foo2::foo3::bar'].should_not be_nil
      Log4r::Logger['foo1::foo2::foo3::bar'].parent.should == Log4r::Logger['foo1::foo2::foo3']
    end

    it "only creates loggers once" do
      Log4r::Logger.should_receive(:new).twice.and_call_original
      Lumber.find_or_create_logger("bar1::bar2")
      Lumber.find_or_create_logger("bar1::bar2")
    end

  end

  describe "#setup_logger_hierarchy" do

    it "should allow registering logger for a class before the class is defined" do
      defined?(Foo1).should be_false
      Lumber.setup_logger_hierarchy("Foo1", "root::foo1")
      new_class('Foo1')
      assert_valid_logger('Foo1', "root::foo1")
    end

    it "should not register new logger for subclasses of classes that delegate logger" do
      defined?(Foo1).should be_false # ActionController::Base
      defined?(Foo2).should be_false # ActionView::Base
      defined?(Foo3).should be_false # Subclass of ActionView::Base
      Lumber.setup_logger_hierarchy("Foo1", "root::foo1")
      eval "class ::Foo1; end"
      eval "class ::Foo2; delegate :logger, :to => Foo1; end"
      eval "class ::Foo3 < Foo2; end"
      assert_valid_logger('Foo1', "root::foo1")
      Foo2.new.logger.should == Foo1.logger
      Foo3.new.logger.should == Foo1.logger
    end

    it "should no logger when parent is via delegate class" do
      defined?(Foo1).should be_false
      defined?(Foo2).should be_false
      defined?(Foo3).should be_false
      Lumber.setup_logger_hierarchy("Foo1", "root::foo1")
      eval "class ::Foo1; end"
      eval "class ::Foo2 < DelegateClass(Foo1); end"
      eval "class ::Foo3 < Foo2; end"
      assert_valid_logger('Foo1', "root::foo1")
      defined?(Foo3.logger).should be_false
    end

    it "should allow registering independent loggers for classes in a hierarchy" do
      defined?(Foo1).should be_false
      defined?(Foo2).should be_false
      Lumber.setup_logger_hierarchy("Foo1", "root::foo1")
      Lumber.setup_logger_hierarchy("Foo2", "root::foo2")
      new_class('Foo1')
      new_class('Foo2', 'Foo1')
      assert_valid_logger('Foo1', "root::foo1")
      assert_valid_logger('Foo2', "root::foo2")
    end

    it "should prevent cattr_accessor for a class registered before the class is defined" do
      defined?(Foo1).should be_false
      Lumber.setup_logger_hierarchy("Foo1", "root::foo1")
      new_class('Foo1')
      Foo1.class_eval do
        cattr_accessor :logger, :foo
      end
      defined?(Foo1.foo).should be_true
      assert_valid_logger('Foo1', "root::foo1")
    end

    it "should allow registering logger for a nested class before the class is defined" do
      defined?(Bar1::Foo1).should be_false
      Lumber.setup_logger_hierarchy("Bar1::Foo1", "root::foo1")
      new_class('Foo1', nil, 'Bar1')
      assert_valid_logger('Bar1::Foo1', "root::foo1")
    end

    it "should allow registering logger for a class after the class is defined" do
      defined?(Foo1).should be_false
      new_class('Foo1')
      defined?(Foo1).should be_true

      Lumber.setup_logger_hierarchy("Foo1", "root::Foo1")
      assert_valid_logger('Foo1', "root::Foo1")
    end

    it "should register loggers for subclasses of registered classes" do
      defined?(Foo1).should be_false
      defined?(Foo2).should be_false
      defined?(Foo3).should be_false
      Lumber.setup_logger_hierarchy("Foo1", "root::Foo1")
      new_class('Foo1')
      new_class('Foo2', 'Foo1')
      new_class('Foo3')
      assert_valid_logger('Foo1', "root::Foo1")
      assert_valid_logger('Foo2', "root::Foo1::Foo2")
      defined?(Foo3.logger).should be_false
    end

    it "should register loggers for sub-subclasses of registered classes" do
      defined?(Foo1).should be_false
      defined?(Foo2).should be_false
      defined?(Foo3).should be_false
      Lumber.setup_logger_hierarchy("Foo1", "root::Foo1")
      new_class('Foo1')
      new_class('Foo2', 'Foo1')
      new_class('Foo3', 'Foo2')
      assert_valid_logger('Foo1', "root::Foo1")
      assert_valid_logger('Foo2', "root::Foo1::Foo2")
      assert_valid_logger('Foo3', "root::Foo1::Foo3")
    end

    it "should register loggers for sub-subclasses of registered classes even when middle class not a logger" do
      defined?(Foo1).should be_false
      defined?(Foo2).should be_false
      defined?(Foo3).should be_false
      new_class('Foo1')
      new_class('Foo2', 'Foo1')
      Lumber.setup_logger_hierarchy("Foo1", "root::Foo1")
      new_class('Foo3', 'Foo2')
      assert_valid_logger('Foo1', "root::Foo1")
      assert_valid_logger('Foo3', "root::Foo1::Foo3")
      assert_valid_logger('Foo2', "root::Foo1::Foo2")
    end

  end

  context "formatted MDC context" do
    
    before(:each) do
      Log4r::MDC.get_context.keys.each {|k| Log4r::MDC.remove(k) }
    end
    
    it "is empty for no context" do
      Lumber.format_mdc.should == ""
    end
    
    it "has context vars" do
      Log4r::MDC.put("baz", "boo")
      Log4r::MDC.put("foo", "bar")
      Lumber.format_mdc.should == "baz=boo foo=bar"
    end
    
    it "escapes %" do
      Log4r::MDC.put("%foo", "%bar")
      Lumber.format_mdc.should == "%%foo=%%bar"
    end
    
  end
  
end
