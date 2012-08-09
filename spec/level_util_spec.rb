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
  
  it "activates level on logger" do
    Lumber.find_or_create_logger(@name)
    LevelUtil.set_levels({@name => "ERROR"})
    Log4r::Logger[@name].level.should == Log4r::LNAMES.index("DEBUG")
    LevelUtil.activate_levels
    Log4r::Logger[@name].level.should == Log4r::LNAMES.index("ERROR")
  end
  
  it "activates level on outputter" do
    logger = Lumber.find_or_create_logger(@name)
    sio = StringIO.new 
    outputter = Log4r::IOOutputter.new("sbout", sio)
    logger.outputters = [outputter]
        
    LevelUtil.set_levels({"sbout" => "ERROR"})
    Log4r::Logger[@name].level.should == Log4r::LNAMES.index("DEBUG")
    outputter.level.should == Log4r::LNAMES.index("DEBUG")
    LevelUtil.activate_levels
    Log4r::Logger[@name].level.should == Log4r::LNAMES.index("DEBUG")
    outputter.level.should == Log4r::LNAMES.index("ERROR")
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
  
  it "restores levels on outputter when mapping expires" do
    logger = Lumber.find_or_create_logger(@name)
    sio = StringIO.new 
    outputter = Log4r::IOOutputter.new("sbout", sio)
    logger.outputters = [outputter]

    outputter.level.should == Log4r::LNAMES.index("DEBUG")

    LevelUtil.set_levels({"sbout" => "ERROR"})
    LevelUtil.activate_levels
    outputter.level.should == Log4r::LNAMES.index("ERROR")

    LevelUtil.set_levels({})
    LevelUtil.activate_levels
    outputter.level.should == Log4r::LNAMES.index("DEBUG")
  end
  
  it "doesn't set levels if already set" do
    logger = Lumber.find_or_create_logger(@name)
    sio = StringIO.new 
    outputter = Log4r::IOOutputter.new("sbout", sio)
    logger.outputters = [outputter]

    outputter.level.should == Log4r::LNAMES.index("DEBUG")
    Log4r::Logger[@name].level.should == Log4r::LNAMES.index("DEBUG")
    
    outputter.should_not_receive(:level=)
    Log4r::Logger[@name].should_not_receive(:level=)
    
    LevelUtil.set_levels({"sbout" => "DEBUG", @name => "DEBUG"})
    LevelUtil.activate_levels
    
    LevelUtil.set_levels({})
    LevelUtil.activate_levels
  end
  
  it "starts a monitor thread" do
    LevelUtil.set_levels({@name => "DEBUG"})
    LevelUtil.activate_levels
    Log4r::Logger[@name].level.should == Log4r::LNAMES.index("DEBUG")
    
    old_size = Thread.list.size
    thread = LevelUtil.start_monitor(0.1)
    thread.should_not be_nil
    thread.should be_alive
    Thread.list.size.should == old_size + 1

    # test that monitor thread has a nice name
    Thread.list.collect {|t| t.to_s }.should be_any { |m| m =~ /Lumber::LevelUtil::MonitorThread/ }
    
    Log4r::Logger[@name].level.should == Log4r::LNAMES.index("DEBUG")
    LevelUtil.set_levels({@name => "ERROR"})
    sleep 0.2
    Log4r::Logger[@name].level.should == Log4r::LNAMES.index("ERROR")
    thread.kill
    thread.join
  end
  
end
