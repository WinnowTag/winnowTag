require File.dirname(__FILE__) + '/../spec_helper'

describe "folders" do
  fixtures :users
  
  before(:each) do
    Folder.delete_all
    
    login
    open feed_items_path
    wait_for_ajax
  end
  
  it "can be created"
  it "can be renamed"
  it "can be destroyed"
  it "can have feeds added"
  it "can have feeds removed"
  it "can have private tags added"
  it "can have private tags removed"
  it "can have public tags added"
  it "can have public tags removed"
  it "can have private tags renamed"
  it "can have a feed moved to a custom folder"
  it "can have a feed removed from a custom folder"
  it "can have a private tag moved to a custom folder"
  it "can have a private tag removed from a custom folder"
  it "can have a public tag moved to a custom folder"
  it "can have a public tag removed from a custom folder"
  it "can have private tags renamed in custom folders"
end
