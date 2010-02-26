# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
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

    page.click "css=#feed_item_#{@feed_item1.id} div.closed"
    page.wait_for :wait_for => :ajax
    see_element "#feed_item_#{@feed_item1.id}.read"

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

  it "opening_item_marks_it_read" do
    dont_see_element "#feed_item_#{@feed_item1.id}.read"

    page.click "css=#feed_item_#{@feed_item1.id} .closed"
    see_element "#feed_item_#{@feed_item1.id}.read"
  end
  
  it "displays an empty message when there are no feed items" do
    FeedItem.delete_all
    sleep(1)
    page.open feed_items_path
    page.wait_for :wait_for => :ajax
  
    see_element "#content .empty"
  end
  
  it "does not display an empty message when there are feed items" do
    dont_see_element "#content .empty"
  end
end
