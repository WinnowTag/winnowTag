# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe "filter controls" do
  before(:each) do
    @user = Generate.user!

    login @user
    page.open feed_items_path
    page.wait_for :wait_for => :ajax
  end
  
  describe "folders" do
    it "is closed by default" do
      assert_not_visible "css=#tags_section .filter_list"
      assert_not_visible "css=#feeds_section .filter_list"
    end
    
    it "opens when clicked" do
      page.click "css=#tags_section .header .toggle_button"
      assert_visible "css=#tags_section .filter_list"
      
      page.click "css=#feeds_section .header .toggle_button"
      assert_visible "css=#feeds_section .filter_list"
      
      
      page.click "css=#tags_section .header .toggle_button"
      assert_not_visible "css=#tags_section .filter_list"
      
      page.click "css=#feeds_section .header .toggle_button"
      assert_not_visible "css=#feeds_section .filter_list"
    end
  end
    
  describe "text filter" do    
    it "sets the text filter" do
      page.location.should =~ /\#order=date&direction=desc&mode=unread$/

      page.type "text_filter", "ruby"
      hit_enter "text_filter"

      page.location.should =~ /\#order=date&direction=desc&mode=unread&text_filter=ruby$/
    end
    
    it "keeps mode and tag/feed filters intact" do
      page.open login_path
      page.open feed_items_path(:anchor => "mode=trained&tag_ids=1&feed_ids=1")
      page.wait_for :wait_for => :ajax

      page.location.should =~ /\#order=date&direction=desc&mode=trained&tag_ids=1&feed_ids=1$/

      page.type "text_filter", "ruby"
      hit_enter "text_filter"

      page.location.should =~ /\#order=date&direction=desc&mode=trained&tag_ids=1&feed_ids=1&text_filter=ruby$/
    end
  end
  
  
  describe "tag filter" do
    before(:each) do
      @tag = Generate.tag!(:user => @user)
      @sql = Generate.tag!(:user => @user)
      page.open feed_items_path
      page.wait_for :wait_for => :ajax
    end
    
    it "sets the tag filter" do
      page.location.should =~ /\#order=date&direction=desc&mode=unread$/

      page.click "css=#name_tag_#{@tag.id}"

      page.location.should =~ /\#order=date&direction=desc&mode=unread&tag_ids=#{@tag.id}$/
    end
    
    it "resets feed/tag filters only" do
      page.open login_path
      page.open feed_items_path(:anchor => "mode=trained&text_filter=ruby&feed_ids=1&tag_ids=999")
      page.wait_for :wait_for => :ajax

      page.location.should =~ /\#order=date&direction=desc&mode=trained&tag_ids=999&feed_ids=1&text_filter=ruby$/

      page.click "css=#name_tag_#{@tag.id}"
      
      page.location.should =~ /\#order=date&direction=desc&mode=trained&tag_ids=#{@tag.id}&text_filter=ruby$/
    end
    
    it "turns off a tag filter" do
      page.open login_path
      page.open feed_items_path(:anchor => "tag_ids=1,#{@tag.id}")
      page.wait_for :wait_for => :ajax

      page.location.should =~ /\#order=date&direction=desc&mode=unread&tag_ids=1%2C#{@tag.id}$/

      page.click "css=#name_tag_#{@tag.id}"
      
      page.location.should =~ /\#order=date&direction=desc&mode=unread&tag_ids=#{@tag.id}$/
    end
    
    it "sets tag filter for all in folder" do
      page.location.should =~ /\#order=date&direction=desc&mode=unread$/

      page.click "css=#tags_section .header .name"
      
      page.location.should =~ /\#order=date&direction=desc&mode=unread&tag_ids=#{@tag.id}%2C#{@sql.id}$/
    end
    
    it "filters by all tags in the folder, even when a tag was just removed" do
      page.location.should =~ /\#order=date&direction=desc&mode=unread$/
      page.click "css=#tag_#{@tag.id} .filter .remove"
      page.wait_for :wait_for => :ajax
      page.confirmation.should include(@tag.name)
      page.click "css=#tags_section .header .name"      
      page.location.should =~ /\#order=date&direction=desc&mode=unread&tag_ids=#{@sql.id}$/
    end
  end
end
