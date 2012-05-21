require 'spec_helper'

describe Lumber::Server, :type => :request do

  before(:each) do
    Capybara.app = Lumber::Server.new
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
