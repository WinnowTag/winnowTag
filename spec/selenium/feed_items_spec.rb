# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe "FeedItemsTest" do
  before(:each) do
    @user = Generate.user!
    
    @feed_item1 = Generate.feed_item!
    @feed_item2 = Generate.feed_item!
    @feed_item3 = Generate.feed_item!
    @feed_item4 = Generate.feed_item!
    
    Reading.create! :user_id => @user, :readable_type => "FeedItem", :readable => @feed_item2
    Reading.create! :user_id => @user, :readable_type => "FeedItem", :readable => @feed_item3
    Reading.create! :user_id => @user, :readable_type => "FeedItem", :readable => @feed_item4
    
    login @user
    page.open feed_items_path
    page.wait_for :wait_for => :ajax
  end

  it "mark_read_unread" do
    dont_see_element "#feed_item_#{@feed_item1.id}.read"

    page.click "css=#feed_item_#{@feed_item1.id} .status"
    see_element "#feed_item_#{@feed_item1.id}.read"
    
    page.refresh
    page.wait_for :wait_for => :page
    page.wait_for :wait_for => :ajax
    dont_see_element "#feed_item_#{@feed_item1.id}"

    # TODO: Make this work with mode=all
    # click "css=#feed_item_#{@feed_item1.id} .status a"
    # see_element "#feed_item_#{@feed_item1.id}.read"
    # 
    # refresh_and_wait
    # wait_for_ajax
    # see_element "#feed_item_#{@feed_item1.id}.read"
  end
  
  it "open_close_item" do
    assert_not_visible "css=#feed_item_#{@feed_item1.id} .body"
    
    page.click "css=#feed_item_#{@feed_item1.id} .closed"
    assert_visible "css=#feed_item_#{@feed_item1.id} .body"
    
    page.click "css=#feed_item_#{@feed_item1.id} .closed"
    assert_not_visible "css=#feed_item_#{@feed_item1.id} .body"
  end

  it "open_close_moderation_panel " do
    assert_not_visible "css=#feed_item_#{@feed_item1.id} .moderation_panel"
 
    page.click "css=#feed_item_#{@feed_item1.id} .train" 
    assert_visible "css=#feed_item_#{@feed_item1.id} .moderation_panel"
 
    page.click "css=#feed_item_#{@feed_item1.id} .train" 
    assert_not_visible "css=#feed_item_#{@feed_item1.id} .moderation_panel"
  end 
  
  it "open_close_moderation_panel_does_not_open_close_item" do
    assert_not_visible "css=#feed_item_#{@feed_item1.id} .body"
    page.click "css=#feed_item_#{@feed_item1.id} .train" 
    assert_not_visible "css=#feed_item_#{@feed_item1.id} .body"
  end
  
  it "opening_item_marks_it_read" do
    dont_see_element "#feed_item_#{@feed_item1.id}.read"

    page.click "css=#feed_item_#{@feed_item1.id} .closed"
    see_element "#feed_item_#{@feed_item1.id}.read"

    page.refresh
    page.wait_for :wait_for => :page
    page.wait_for :wait_for => :ajax
    dont_see_element "#feed_item_#{@feed_item1.id}"
  end
  
  it "click_feed_title_takes_you_to_feed_page" do
    windows = page.get_all_window_ids
    feed1 = @feed_item1.feed
    page.click "css=#feed_item_#{@feed_item1.id} .feed_title", :wait_for => :ajax
    page.click "css=#feed_item_#{@feed_item1.id} #feed_#{feed1.id} a[href=/feed_items#feed_ids=#{feed1.id}]"
    page.get_all_window_names.should have(windows.size + 1).windows
  end
  
  it "displays an empty message when there are no feed items" do
    FeedItem.delete_all
    
    page.open feed_items_path
    page.wait_for :wait_for => :ajax
  
    see_element "#content .empty"
  end
  
  it "does not display an empty message when there are feed items" do
    dont_see_element "#feed_items .empty"
  end
end
