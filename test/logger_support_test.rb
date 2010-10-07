require 'test_helper.rb'

class LoggerSupportTest < Test::Unit::TestCase

  def setup
    root = "#{File.dirname(__FILE__)}/.."
    Lumber.init(:root => root,
                :env => 'test',
                :config_file => "#{root}/generators/lumber/templates/log4r.yml",
                :log_file => "/tmp/lumber-test.log")
  end

  def teardown
    LoggerSupportTest.constants.grep(/^Foo/).each do |c|
      LoggerSupportTest.send(:remove_const, c)
    end
  end

  should "create logger for chain" do
    class Foo; include Lumber::LoggerSupport; end
    class Bar < Foo; end;
    assert_equal Foo.logger, Log4r::Logger["rails::LoggerSupportTest::Foo"]
    assert_equal Bar.logger, Log4r::Logger["rails::LoggerSupportTest::Foo::Bar"]
    assert_equal Bar.logger.parent, Log4r::Logger["rails::LoggerSupportTest::Foo"]
  end

  should "have a logger instance accessible from an instance method" do
    logger = stub_everything()
    Log4r::Logger.stubs(:new).returns(logger)
    class Foo; include Lumber::LoggerSupport; def member_method; logger.debug('hi'); end; end
    logger.expects(:debug).with('hi')
    Foo.new.member_method
  end

  should "have a logger instance accessible from a class method " do
    logger = stub_everything()
    Log4r::Logger.stubs(:new).returns(logger)
    class Foo; include Lumber::LoggerSupport; def self.class_method; logger.debug('hi'); end; end
    logger.expects(:debug).with('hi')
    Foo.class_method
  end

end
