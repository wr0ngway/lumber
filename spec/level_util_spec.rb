require 'spec_helper'

describe Lumber::LevelUtil do
  
  before(:each) do
    # re-initialize lumber
    root = "#{File.dirname(__FILE__)}/.."
    Lumber.init(:root => root,
                :env => 'test',
                :config_file => "#{root}/generators/lumber/templates/log4r.yml",
                :log_file => "/tmp/lumber-test.log")

    @name = "foo_#{Time.now.to_f}"
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
    LevelUtil.set_levels({@name => "DEBUG"})
    LevelUtil.get_levels.should == {@name => "DEBUG"}
  end
  
  it "creates logger if not yet defined" do
    Log4r::Logger["unknownlogger"].should be_nil
    LevelUtil.set_levels({"unknownlogger" => "DEBUG"})
    LevelUtil.activate_levels
    Log4r::Logger["unknownlogger"].should_not be_nil
  end
  
  it "reuses logger if already defined" do
    foo_logger = Lumber.find_or_create_logger(@name)
    foo_logger.should_not be_nil

    LevelUtil.set_levels({@name => "INFO"})
    LevelUtil.activate_levels
    Log4r::Logger[@name].should == foo_logger
  end
  
  it "activate level on logger" do
    Lumber.find_or_create_logger(@name)
    LevelUtil.set_levels({@name => "ERROR"})
    Log4r::Logger[@name].level.should == Log4r::LNAMES.index("DEBUG")
    LevelUtil.activate_levels
    Log4r::Logger[@name].level.should == Log4r::LNAMES.index("ERROR")
  end
  
  it "restores levels when mapping expires" do
    Lumber.find_or_create_logger(@name)
    Log4r::Logger[@name].level.should == Log4r::LNAMES.index("DEBUG")

    LevelUtil.set_levels({@name => "ERROR"})
    LevelUtil.activate_levels
    Log4r::Logger[@name].level.should == Log4r::LNAMES.index("ERROR")

    LevelUtil.set_levels({})
    LevelUtil.activate_levels
    Log4r::Logger[@name].level.should == Log4r::LNAMES.index("DEBUG")
  end
  
  it "starts a monitor thread" do
    LevelUtil.set_levels({@name => "DEBUG"})
    LevelUtil.activate_levels
    Log4r::Logger[@name].level.should == Log4r::LNAMES.index("DEBUG")
    
    thread = LevelUtil.start_monitor(0.1)
    thread.should_not be_nil
    thread.should be_alive
    
    Log4r::Logger[@name].level.should == Log4r::LNAMES.index("DEBUG")
    LevelUtil.set_levels({@name => "ERROR"})
    sleep 0.2
    Log4r::Logger[@name].level.should == Log4r::LNAMES.index("ERROR")
    thread.kill
    thread.join
  end
  
end
