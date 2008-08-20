# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe "filter controls" do
  fixtures :users, :tags

  before(:each) do
    @user = users(:quentin)
    login
    open feed_items_path
    wait_for_ajax
  end
  
  describe "folders" do
    it "is closed by default" do
      assert_not_visible "css=#tags_section .filter_list"
      assert_not_visible "css=#feeds_section .filter_list"
    end
    
    it "opens when clicked" do
      click "css=#tags_section .header .toggle_button"
      assert_visible "css=#tags_section .filter_list"
      
      click "css=#feeds_section .header .toggle_button"
      assert_visible "css=#feeds_section .filter_list"
      
      
      click "css=#tags_section .header .toggle_button"
      assert_not_visible "css=#tags_section .filter_list"
      
      click "css=#feeds_section .header .toggle_button"
      assert_not_visible "css=#feeds_section .filter_list"
    end
  end
    
  describe "text filter" do    
    it "sets the text filter" do
      get_location.should =~ /\#order=date&direction=desc$/

      type "text_filter", "ruby"
      hit_enter "text_filter"

      get_location.should =~ /\#order=date&direction=desc&text_filter=ruby$/
    end
    
    it "keeps mode and tag/feed filters intact" do
      open login_path
      open feed_items_path(:anchor => "mode=trained&tag_ids=1&feed_ids=1")
      wait_for_ajax

      get_location.should =~ /\#order=date&direction=desc&tag_ids=1&feed_ids=1&mode=trained$/

      type "text_filter", "ruby"
      hit_enter "text_filter"

      get_location.should =~ /\#order=date&direction=desc&tag_ids=1&feed_ids=1&mode=trained&text_filter=ruby$/
    end
  end
  
  
  describe "tag filter" do
    before(:each) do
      Tag.delete_all
      @tag = Tag.create! :name => "ruby", :user => users(:quentin)
      @sql = Tag.create! :name => "sql", :user => users(:quentin)
      open feed_items_path
      wait_for_ajax
    end
    
    it "sets the tag filter" do
      get_location.should =~ /\#order=date&direction=desc$/

      click "css=#name_tag_#{@tag.id}"

      get_location.should =~ /\#order=date&direction=desc&tag_ids=#{@tag.id}$/
    end
    
    it "resets feed/tag filters only" do
      open login_path
      open feed_items_path(:anchor => "mode=trained&text_filter=ruby&feed_ids=1&tag_ids=999")
      wait_for_ajax

      get_location.should =~ /\#order=date&direction=desc&tag_ids=999&feed_ids=1&mode=trained&text_filter=ruby$/

      click "css=#name_tag_#{@tag.id}"
      
      get_location.should =~ /\#order=date&direction=desc&tag_ids=#{@tag.id}&mode=trained&text_filter=ruby$/
    end
    
    it "turns off a tag filter" do
      open login_path
      open feed_items_path(:anchor => "tag_ids=1,#{@tag.id}")
      wait_for_ajax

      get_location.should =~ /\#order=date&direction=desc&tag_ids=1%2C#{@tag.id}$/

      click "css=#name_tag_#{@tag.id}"
      
      get_location.should =~ /\#order=date&direction=desc&tag_ids=#{@tag.id}$/
    end
    
    it "sets tag filter for all in folder" do
      get_location.should =~ /\#order=date&direction=desc$/

      click "css=#tag_filters_control"
      
      get_location.should =~ /\#order=date&direction=desc&tag_ids=#{@tag.id}%2C#{@sql.id}$/
    end
    
    it "filters by all tags in the folder, even when a tag was just removed" do
      get_location.should =~ /\#order=date&direction=desc$/
      click "css=#tag_#{@tag.id} .filter .remove"
      wait_for_ajax
      get_confirmation.should include(@tag.name)
      click "css=#tag_filters_control"      
      get_location.should =~ /\#order=date&direction=desc&tag_ids=#{@sql.id}$/
    end
  end
end
