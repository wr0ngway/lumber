require 'test_helper'


def new_class(class_name, super_class=nil, super_module=nil)
  s = "class #{class_name}"
  s << " < #{super_class}" if super_class
  s << "; end"

  s = "module #{super_module}; #{s}; end" if super_module
  
  eval s
end

class LumberTest < Test::Unit::TestCase

  def setup
    root = "#{File.dirname(__FILE__)}/.."
    Lumber.init(:root => root,
                :env => 'test',
                :config_file => "#{root}/generators/lumber/templates/log4r.yml",
                :log_file => "/tmp/lumber-test.log")
  end

  def teardown
    Object.constants.grep(/^Foo/).each do |c|
      Object.send(:remove_const, c)
    end
  end

  def assert_valid_logger(class_name, logger_name)
    clazz = eval class_name
    assert clazz
    assert clazz.respond_to?(:logger)
    lgr = clazz.logger
    assert lgr.instance_of?(Log4r::Logger)
    assert_equal logger_name, lgr.fullname
  end

  should "not do anything if no loggers registered" do
    assert defined?(Object.inherited_with_lumber_log4r)
    assert ! defined?(Object.logger)
  end

  should "allow registering logger for a class before the class is defined" do
    assert !defined?(Foo1)
    Lumber.setup_logger_hierarchy("Foo1", "root::foo1")
    new_class('Foo1')
    assert_valid_logger('Foo1', "root::foo1")
  end

  should "prevent cattr_accessor for a class registered before the class is defined" do
    assert !defined?(Foo1)
    Lumber.setup_logger_hierarchy("Foo1", "root::foo1")
    new_class('Foo1')
    Foo1.class_eval do
      cattr_accessor :logger, :foo
    end
    assert defined?(Foo1.foo)
    assert_valid_logger('Foo1', "root::foo1")
  end

  should "allow registering logger for a nested class before the class is defined" do
    assert !defined?(Bar1::Foo1)
    Lumber.setup_logger_hierarchy("Bar1::Foo1", "root::foo1")
    new_class('Foo1', nil, 'Bar1')
    assert_valid_logger('Bar1::Foo1', "root::foo1")
  end

  should "allow registering logger for a class after the class is defined" do
    assert !defined?(Foo1)
    new_class('Foo1')
    assert defined?(Foo1)

    Lumber.setup_logger_hierarchy("Foo1", "root::Foo1")
    assert_valid_logger('Foo1', "root::Foo1")
  end

  should "register loggers for subclasses of registered classes" do
    assert !defined?(Foo1)
    assert !defined?(Foo2)
    assert !defined?(Foo3)
    Lumber.setup_logger_hierarchy("Foo1", "root::Foo1")
    new_class('Foo1')
    new_class('Foo2', 'Foo1')
    new_class('Foo3')
    assert_valid_logger('Foo1', "root::Foo1")
    assert_valid_logger('Foo2', "root::Foo1::Foo2")
    assert ! defined?(Foo3.logger)
  end

  should "register loggers for sub-subclasses of registered classes" do
    assert !defined?(Foo1)
    assert !defined?(Foo2)
    assert !defined?(Foo3)
    Lumber.setup_logger_hierarchy("Foo1", "root::Foo1")
    new_class('Foo1')
    new_class('Foo2', 'Foo1')
    new_class('Foo3', 'Foo2')
    assert_valid_logger('Foo1', "root::Foo1")
    assert_valid_logger('Foo2', "root::Foo1::Foo2")
    assert_valid_logger('Foo3', "root::Foo1::Foo2::Foo3")
  end

  should "register loggers for sub-subclasses of registered classes even when middle class not a logger" do
    assert !defined?(Foo1)
    assert !defined?(Foo2)
    assert !defined?(Foo3)
    new_class('Foo1')
    new_class('Foo2', 'Foo1')
    Lumber.setup_logger_hierarchy("Foo1", "root::Foo1")
    new_class('Foo3', 'Foo2')
    assert_valid_logger('Foo1', "root::Foo1")
    assert !defined?(Foo2.logger) || Foo2.logger.nil?
    assert_valid_logger('Foo3', "root::Foo1::Foo3")
  end
  
end
