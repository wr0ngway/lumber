require 'test_helper.rb'

class LoggerSupportTest < Test::Unit::TestCase

  def teardown
    Log4r::Logger::Repository.instance.loggers.clear
    LoggerSupportTest.constants.grep(/^Foo/).each do |c|
      LoggerSupportTest.send(:remove_const, c)
    end
  end

  should "create logger for chain" do
    class Foo; include Lumber::LoggerSupport; end
    assert_equal Log4r::Logger["rails::LoggerSupportTest::Foo"], Foo.logger
    assert_equal Log4r::Logger["rails::LoggerSupportTest"], Foo.logger.parent
    assert_equal Log4r::Logger["rails"], Foo.logger.parent.parent
    assert_equal Log4r::Logger.root, Foo.logger.parent.parent.parent
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
