require File.dirname(__FILE__) + '/../spec_helper'

describe "filter controls" do
  fixtures :users

  before(:each) do
    @user = users(:quentin)
    login
    open feed_items_path
  end
  
  describe "show all items" do
    it "is selected by default" do
      see_element "#show_all.selected"
    end
  end
  
  describe "folders" do
    it "is closed by default" do
      assert_not_visible "css=#folder_tags .filter_list"
      assert_not_visible "css=#folder_feeds .filter_list"
    end
    
    it "opens when clicked" do
      click "css=#folder_tags .header"
      assert_visible "css=#folder_tags .filter_list"
      
      click "css=#folder_feeds .header"
      assert_visible "css=#folder_feeds .filter_list"
      
      
      click "css=#folder_tags .header"
      assert_not_visible "css=#folder_tags .filter_list"
      
      click "css=#folder_feeds .header"
      assert_not_visible "css=#folder_feeds .filter_list"
    end
    
    # it "is gray when ..." do
    #   mouse_over "css=#folder_tags .header"
    #   get_style('#folder_tags .header', 'background-color').should == "#eee"
    # end
  end
  
  # describe "tags" do
  #   before(:each) do
  #     @rails_tag = Tag.create! :user => @user, :name => "rails"
  #   end
  #   
  #   after(:each) do
  #     @rails_tag.destroy
  #   end
  #   
  #   it "is not selected by default" do
  #     dont_see_element "#show_all.selected"
  #   end
  #   
  #   it "is selected when clicked" do
  #     click "css=#show_all.selected"
  #     see_element "#show_all.selected"
  #     
  #     click "css=#show_all.selected"
  #     dont_see_element "#show_all.selected"
  #   end
  # end
end