# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe "Feed Filtering" do
  before(:each) do
    @user = Generate.user!
    
    @feed1 = Generate.feed!
    @feed2 = Generate.feed!
    
    @feed_item1 = Generate.feed_item! :feed => @feed1
    @feed_item2 = Generate.feed_item! :feed => @feed1
    @feed_item3 = Generate.feed_item! :feed => @feed2
    @feed_item4 = Generate.feed_item! :feed => @feed2
    
    @tag = Generate.tag! :user => @user
    
    login @user
    page.open feed_items_path
    page.wait_for :wait_for => :ajax
  end

  it "should filter by the feed when clicked" do
    click_feed1
    page.location.should match(/feed_ids=#{@feed1.id}/)
    
    see_element("#feed_item_#{@feed_item1.id}")
    see_element("#feed_item_#{@feed_item2.id}")
    dont_see_element("#feed_item_#{@feed_item3.id}")
    dont_see_element("#feed_item_#{@feed_item4.id}")
  end
  
  it "should show the feed in the feed selection banner" do
    click_feed1
    
    see_element("#selectedFeed")
    page.get_text("filteredFeedTitle").should == @feed1.title
  end
  
  it "should cancel the filtering when the cancel button is pressed" do
    click_feed1
    
    page.click("css=#selectedFeed a")
    page.wait_for :wait_for => :ajax
    page.location.should_not match(/feed_ids=#{@feed1.id}/)
    
    see_element("#feed_item_#{@feed_item1.id}")
    see_element("#feed_item_#{@feed_item2.id}")
    see_element("#feed_item_#{@feed_item3.id}")
    see_element("#feed_item_#{@feed_item4.id}")
  end
  
  it "should cancel feed filtering when a tag is clicked" do
    click_feed1
    
    page.click("css=#tag_#{@tag.id} .name")
    page.wait_for :wait_for => :ajax
    page.location.should_not match(/feed_ids/)
  end
  
  def click_feed1
    page.click("css=#feed_item_#{@feed_item1.id} a.feed_title")
    page.wait_for :wait_for => :ajax
    page.click("css=#feed_#{@feed1.id} a.feed_filter_link")
    page.wait_for :wait_for => :ajax
  end
  
  def click_feed2
    page.click("css=#feed_item_#{@feed_item3.id} a.feed_title")
    page.wait_for :wait_for => :ajax
    page.click("css=#feed_#{@feed2.id} a.feed_filter_link")
    page.wait_for :wait_for => :ajax
  end
end
