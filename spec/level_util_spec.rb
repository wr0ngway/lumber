require 'spec_helper'

describe Lumber::LevelUtil do
  
  before(:each) do
    root = "#{File.dirname(__FILE__)}/.."
    Lumber.init(:root => root,
                :env => 'test',
                :config_file => "#{root}/generators/lumber/templates/log4r.yml",
                :log_file => "/tmp/lumber-test.log")
  end

  it "has a default cache provider" do
    LevelUtil.cache_provider.should be_instance_of LevelUtil::MemoryCacheProvider
  end
  
  it "can be assigned a cache provider" do
    class Foo < LevelUtil::MemoryCacheProvider; end
    LevelUtil.cache_provider = Foo.new
    LevelUtil.cache_provider.should be_instance_of Foo
  end
  
  it "can roundtrip levels" do
    LevelUtil.get_levels.should == {}
    LevelUtil.set_levels({"foo" => "DEBUG"})
    LevelUtil.get_levels.should == {"foo" => "DEBUG"}
  end
  
  it "creates logger if not yet defined" do
    Log4r::Logger["unknownlogger"].should be_nil
    LevelUtil.set_levels({"unknownlogger" => "DEBUG"})
    Log4r::Logger["unknownlogger"].should_not be_nil
  end
  
  it "reuses logger if already defined" do
    LevelUtil.set_levels({"foo" => "DEBUG"})
    foo_logger = Log4r::Logger["foo"]
    foo_logger.should_not be_nil
    LevelUtil.set_levels({"foo" => "INFO"})
    Log4r::Logger["foo"].should == foo_logger
  end
  
  it "activate level on logger" do
    LevelUtil.set_levels({"foo" => "ERROR"})
    Log4r::Logger["foo"].level.should == Log4r::LNAMES.index("DEBUG")
    LevelUtil.activate_levels
    Log4r::Logger["foo"].level.should == Log4r::LNAMES.index("ERROR")
  end
  
  it "restores levels when mapping expires" do
    LevelUtil.set_levels({"bar" => "ERROR"})
    Log4r::Logger["bar"].level.should == Log4r::LNAMES.index("DEBUG")
    
    LevelUtil.activate_levels
    Log4r::Logger["bar"].level.should == Log4r::LNAMES.index("ERROR")

    LevelUtil.set_levels({})
    LevelUtil.activate_levels
    Log4r::Logger["bar"].level.should == Log4r::LNAMES.index("DEBUG")
  end
  
end
