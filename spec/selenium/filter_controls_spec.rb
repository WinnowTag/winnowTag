require File.dirname(__FILE__) + '/../spec_helper'

describe "filter controls" do
  fixtures :users, :tags

  before(:each) do
    @user = users(:quentin)
    login
    open feed_items_path
    wait_for_ajax
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
  
  describe "manual taggings filter" do
    it "turns on manual taggings" do
      get_location.should =~ /\#$/
      click "css=#manual_taggings_filter"
      get_location.should =~ /\#manual_taggings=true$/
    end
    
    it "keeps text and tag/feed filters intact" do
      open login_path
      open feed_items_path(:anchor => "text_filter=ruby&tag_ids=1&feed_ids=1")
      wait_for_ajax

      get_location.should =~ /\#text_filter=ruby&tag_ids=1&feed_ids=1$/
      click "css=#manual_taggings_filter"
      get_location.should =~ /\#text_filter=ruby&tag_ids=1&feed_ids=1&manual_taggings=true$/
    end
  end
  
  describe "read items filter" do
    it "turns on read items" do
      get_location.should =~ /\#$/
      click "css=#read_items_filter"
      get_location.should =~ /\#read_items=true$/
    end
    
    it "keeps text and tag/feed filters intact" do
      open login_path
      open feed_items_path(:anchor => "text_filter=ruby&tag_ids=1&feed_ids=1")
      wait_for_ajax

      get_location.should =~ /\#text_filter=ruby&tag_ids=1&feed_ids=1$/
      click "css=#read_items_filter"
      get_location.should =~ /\#text_filter=ruby&tag_ids=1&feed_ids=1&read_items=true$/
    end
  end
  
  describe "text filter" do    
    it "sets the text filter" do
      click "css=#show_all"
      wait_for_ajax
      
      get_location.should =~ /\#$/

      type "text_filter", "ruby"
      hit_enter "text_filter"

      get_location.should =~ /\#text_filter=ruby$/
    end
    
    it "keeps manual taggings and tag/feed filters intact" do
      open login_path
      open feed_items_path(:anchor => "manual_taggings=true&tag_ids=1&feed_ids=1")
      wait_for_ajax

      get_location.should =~ /\#manual_taggings=true&tag_ids=1&feed_ids=1$/

      type "text_filter", "ruby"
      hit_enter "text_filter"

      get_location.should =~ /\#manual_taggings=true&tag_ids=1&feed_ids=1&text_filter=ruby$/
    end
  end
  
  
  describe "tag filter" do
    before(:each) do
      Tag.delete_all
      @tag = Tag.create! :name => "ruby", :user => users(:quentin)
      @sql = Tag.create! :name => "sql", :user => users(:quentin)
      open feed_items_path
    end
    
    it "sets the tag filter" do
      click "css=#show_all"
      wait_for_ajax
      
      get_location.should =~ /\#$/

      click "css=#name_tag_#{@tag.id}"

      get_location.should =~ /\#tag_ids=#{@tag.id}$/
    end
    
    it "resets manual taggings filter, text filter, and any other feed/tag filters" do
      open login_path
      open feed_items_path(:anchor => "manual_taggings=true&text_filter=ruby&feed_ids=1")
      wait_for_ajax

      get_location.should =~ /\#manual_taggings=true&text_filter=ruby&feed_ids=1$/

      click "css=#name_tag_#{@tag.id}"
      
      get_location.should =~ /\#tag_ids=#{@tag.id}$/
    end
    
    it "turns off a tag filter" do
      open login_path
      open feed_items_path(:anchor => "tag_ids=1,#{@tag.id}")
      wait_for_ajax

      get_location.should =~ /\#tag_ids=1%2C#{@tag.id}$/

      click "css=#name_tag_#{@tag.id}"
      
      get_location.should =~ /\#tag_ids=#{@tag.id}$/
    end
    
    it "sets tag filter for all in folder" do
      click "css=#show_all"
      wait_for_ajax

      get_location.should =~ /\#$/

      click "css=#tag_filters_control"
      
      get_location.should =~ /\#tag_ids=#{@tag.id}%2C#{@sql.id}$/
    end
    
    xit "filters by all tags in the folder, even when the tag was just added"

    it "filters by all tags in the folder, even when a tag was just removed" do
      open feed_items_path
      click "css=#show_all"
      wait_for_ajax

      get_location.should =~ /\#$/
      click "css=#tag_#{@tag.id} .show_tag_control .remove"
      click "css=#tag_filters_control"      
      get_location.should =~ /\#tag_ids=#{@sql.id}$/
    end
    
    xit "doesnt scroll the sidebar to the top"
  end
end
