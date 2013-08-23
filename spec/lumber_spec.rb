require 'spec_helper'
require 'delegate'

def new_class(class_name, super_class=nil, super_module=nil)
  s = "class #{class_name}"
  s << " < #{super_class}" if super_class
  s << "; end"

  s = "module #{super_module}; #{s}; end" if super_module

  eval s
end
  
describe Lumber do

  before(:each) do
    root = "#{File.dirname(__FILE__)}/.."
    Lumber.init(:root => root,
                :env => 'test',
                :config_file => "#{root}/generators/lumber/templates/log4r.yml",
                :log_file => "/tmp/lumber-test.log")
  end

  after(:each) do
    Object.constants.grep(/^Foo/).each do |c|
      Object.send(:remove_const, c)
    end
  end

  def assert_valid_logger(class_name, logger_name)
    clazz = eval class_name
    clazz.should_not be_nil
    clazz.respond_to?(:logger).should be_true
    lgr = clazz.logger
    lgr.should be_an_instance_of(Log4r::Logger)
    lgr.fullname.should == logger_name
  end

  it "should not do anything if no loggers registered" do
    defined?(Object.inherited_with_lumber_log4r).should be_true
    defined?(Object.logger).should be_false
  end

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
    assert_valid_logger('Foo3', "root::Foo1::Foo2::Foo3")
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
    # this will behave differently depending on the version of ActiveSupport being used. on ActiveSupport >= 3.2, we use class_attribute to define
    # the logger method, which will cause subclasses to fall back to the parent class's logger if one isn't defined (Foo2.logger == Foo1.logger)
    # if on ActiveSupport < 3.2, we use class_inheritable_accessor, which will leave the logger undefined in the subclass unless LoggerSupport
    # is explicitly included
    ((!defined?(Foo2.logger) || Foo2.logger.nil?) || (Foo2.logger == Foo1.logger)).should be_true
    assert_valid_logger('Foo3', "root::Foo1::Foo3")
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
