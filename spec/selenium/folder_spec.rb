require File.dirname(__FILE__) + '/../spec_helper'

describe "folders" do
  fixtures :users
  
  before(:each) do
    Folder.delete_all
    
    @existing_folder = Folder.create! :user_id => 1, :name => "existing folder"
    
    login
    open feed_items_path
    wait_for_ajax
  end
  
  it "can be created" do
    assert_not_visible "add_folder"

    click "add_folder_link"
    assert_visible "add_folder"
    
    type "folder_name", "new folder"
    hit_enter "folder_name"
    wait_for_ajax
    
    new_folder = Folder.find_by_name("new folder")
    see_element "#folder_#{new_folder.id}"
  end
  
  it "can be renamed"
  
  it "can be destroyed" do
    see_element "#folder_#{@existing_folder.id}"

    click "css=#folder_#{@existing_folder.id} .actions .destroy"
    get_confirmation.should == "Are you sure?"
    wait_for_ajax
    
    dont_see_element "#folder_#{@existing_folder.id}"
  end
  
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
