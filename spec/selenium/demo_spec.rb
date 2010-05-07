# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe "Demo" do
  before(:each) do
    @user = Generate.user!(:login => "pw_demo")
    @tag = @user.tags.create(:name => 'test')
    
    @items = [Generate.feed_item!, Generate.feed_item!, Generate.feed_item!]
    
    @tag.taggings.create!(:feed_item => @items.first, :user => @user)
    
    page.open "/"
    page.wait_for :wait_for => :page
    page.wait_for :wait_for => :ajax
  end
  
  it "should show the see all items pseudo-tag" do
    see_element("#tag_0")
    page.get_text("css=#tag_0").should == "See all items"
  end
  
  it "should hide the tag detail footer when show all items is set" do
    page.is_visible("css=#tag_detail_footer").should be_false
  end
  
  it "should show the tag" do
    see_element("#tag_#{@tag.id}")
  end
  
  it "should show all the items" do
    @items.each do |item|
      see_element("#feed_item_#{item.id}")
    end
  end
  
  it "should switch to tag filter when clicked" do
    page.click("css=#tag_#{@tag.id}")
    page.is_visible("css=#tag_#{@tag.id}.selected").should be_true
  end
  
  it "should show the tag_detail footer when a tag is selected" do
    page.click("css=#tag_#{@tag.id}")
    page.is_visible("css=#tag_detail_footer").should be_true
  end
  
  it "should set the tag details when a tag is selected" do
    page.click("css=#tag_#{@tag.id}")
    page.get_text("css=#footer_tag_name").should == "test"
    page.get_text("css=#footer_tag_positive_count").should == "1"
    page.get_text("css=#footer_tag_negative_count").should == "0"
    page.get_text("css=#footer_tag_count").should == "1"
  end
  
  it "should only show tagged items when the tag is selected" do 
    page.click("css=#tag_#{@tag.id}")
    page.wait_for :wait_for => :ajax
    page.is_visible("css=#feed_item_#{@items.first.id}").should be_true
    page.is_element_present("css=#feed_item_#{@items[1].id}").should be_false
    page.is_element_present("css=#feed_item_#{@items[1].id}").should be_false
  end
  
  it "should open items" do
    page.click("css=#feed_item_#{@items.first.id} .closed")
    page.wait_for :wait_for => :ajax
    assert_visible "css=#feed_item_#{@items.first.id} .body"
    page.get_text("css=#feed_item_#{@items.first.id} .body").should == "Example Content"
  end
end
