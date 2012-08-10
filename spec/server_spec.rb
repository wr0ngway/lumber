require 'spec_helper'

describe Lumber::Server, :type => :request do
  include Rack::Test::Methods
  
  before(:each) do
    Capybara.app = Lumber::Server.new
  end

  def app
    @app ||= Lumber::Server.new
  end
  
  it "should respond to it's url" do
    visit "/levels"
    page.should have_content('Logger Levels')
  end

  it "should show ttl field" do
    visit "/levels"
    find_field('ttl').value.should == LevelUtil.ttl.to_s
  end

  it "shows the active level override" do
    LevelUtil.set_levels({"foo" => "DEBUG"})

    visit "/levels"
    
    within("table.levels") do
      find_field('levels[][name]').value.should == "foo"
      find_field('levels[][level]').value.should == "DEBUG"
    end
  end

  it "shows remove link" do
    LevelUtil.set_levels({"foo" => "DEBUG"})

    visit "/levels"
    page.should have_selector('form a.remove')
  end

  it "shows add link" do
    LevelUtil.set_levels({})
    
    visit "/levels"

    page.should have_selector('form a.add')
  end

  it "has form to edit levels" do
    visit "/levels"

    page.should have_selector('form')
  end
  
  it "uses ttl set in current request" do
    Lumber.find_or_create_logger("foo")
    LevelUtil.cache_provider.should_receive(:write).with(LevelUtil::LOG_LEVELS_KEY, {"foo" => "INFO"}, :expires_in => 55)

    post "/levels", {'ttl' => 55, 'levels' => [{'name' => "foo", "level" => "INFO"}]}
  end
    
  it "assigns level overrides", :js => true do
    LevelUtil.set_levels({})
    
    visit "/levels"
    click_link('Add')
    fill_in 'levels[][name]', :with => "foo"
    fill_in 'levels[][level]', :with => "DEBUG"
    click_button 'Apply'

    page.should_not have_selector("div.alert-error")
    within("table.levels") do
      find_field('levels[][name]').value.should == "foo"
      find_field('levels[][level]').value.should == "DEBUG"
    end
    LevelUtil.get_levels.should == {"foo" => "DEBUG"}
  end
  
  it "shows heirarchy overrides after assigning", :js => true do
    @parent_name = "parent_#{Time.now.to_f}"
    @child_name = "#{@parent_name}::child_#{Time.now.to_f}"
    @other_name = "other_#{Time.now.to_f}"
    Lumber.find_or_create_logger(@parent_name)
    Lumber.find_or_create_logger(@child_name)
    Lumber.find_or_create_logger(@other_name)
    
    LevelUtil.set_levels({})
    
    visit "/levels"
    click_link('Add')
    fill_in 'levels[][name]', :with => @child_name
    fill_in 'levels[][level]', :with => "DEBUG"
    click_button 'Apply'

    page.should_not have_selector("div.alert-error")
    
    find(:xpath, "//input[@value='#{@child_name}']/ancestor::tr//input[@value='DEBUG']").should_not be_nil
    find(:xpath, "//input[@value='#{@parent_name}']/ancestor::tr//input[@value='DEBUG']").should_not be_nil
    
    LevelUtil.get_levels.should == {@child_name => "DEBUG", @parent_name => "DEBUG"}
  end
  
  it "modifies level overrides", :js => true do
    LevelUtil.set_levels({"foo" => "INFO"})
    
    visit "/levels"
    within("table.levels") do
      find_field('levels[][name]').value.should == "foo"
      find_field('levels[][level]').value.should == "INFO"
    end
    fill_in 'levels[][level]', :with => "ERROR"
    click_button 'Apply'

    page.should_not have_selector("div.alert-error")
    within("table.levels") do
      find_field('levels[][name]').value.should == "foo"
      find_field('levels[][level]').value.should == "ERROR"
    end
    LevelUtil.get_levels.should == {"foo" => "ERROR"}
  end
  
  it "deletes level overrides", :js => true do
    LevelUtil.set_levels({"foo" => "DEBUG"})
    
    visit "/levels"
    click_link('Remove')
    click_button 'Apply'

    page.should_not have_selector("div.alert-error")
    LevelUtil.get_levels.should == {}
  end

  it "fails on invalid level", :js => true do
    LevelUtil.set_levels({"foo" => "DEBUG"})
    
    visit "/levels"
    fill_in 'levels[][level]', :with => "badlevel"
    click_button 'Apply'

    page.should have_selector("div.alert-error")
    LevelUtil.get_levels.should == {"foo" => "DEBUG"}
  end

end
