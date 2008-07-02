# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe "FeedItemsTest" do
  fixtures :users, :feed_items, :feeds, :tags

  before(:each) do
    ReadItem.delete_all
    ReadItem.create! :user_id => 1, :feed_item_id => 2
    ReadItem.create! :user_id => 1, :feed_item_id => 3
    ReadItem.create! :user_id => 1, :feed_item_id => 4
    
    delete_cookie "show_sidebar", "/"
    login
    open feed_items_path
    wait_for_ajax
  end

  it "mark_read_unread" do
    feed_item_1 = FeedItem.find(1)
        
    see_element "#feed_item_#{feed_item_1.id}.unread"

    click "css=#feed_item_#{feed_item_1.id} .status a"
    see_element "#feed_item_#{feed_item_1.id}.read"
    
    refresh_and_wait
    wait_for_ajax
    dont_see_element "#feed_item_#{feed_item_1.id}.unread"

    # TODO: Make this work with mode=all
    # click "css=#feed_item_#{feed_item_1.id} .status a"
    # see_element "#feed_item_#{feed_item_1.id}.read"
    # 
    # refresh_and_wait
    # wait_for_ajax
    # see_element "#feed_item_#{feed_item_1.id}.read"
  end
  
  it "open_close_item" do
    feed_item = FeedItem.find(1)

    assert_not_visible "open_feed_item_#{feed_item.id}"
    
    click "css=#feed_item_#{feed_item.id} .opener"
    assert_visible "open_feed_item_#{feed_item.id}"
    
    click "css=#feed_item_#{feed_item.id} .opener"
    assert_not_visible "open_feed_item_#{feed_item.id}"
  end

  it "open_close_moderation_panel " do
    feed_item = FeedItem.find(1)
 
    assert_not_visible "new_tag_form_feed_item_#{feed_item.id}" 
 
    click "add_tag_feed_item_#{feed_item.id}" 
    assert_visible "new_tag_form_feed_item_#{feed_item.id}" 
 
    click "add_tag_feed_item_#{feed_item.id}" 
    assert_not_visible "new_tag_form_feed_item_#{feed_item.id}" 
  end 
  
  it "open_close_moderation_panel_does_not_open_close_item" do
    feed_item = FeedItem.find(1)
    assert_not_visible "open_feed_item_#{feed_item.id}"
    click "add_tag_feed_item_#{feed_item.id}" 
    assert_not_visible "open_feed_item_#{feed_item.id}"
  end
  
  it "opening_item_marks_it_read" do
    feed_item_1 = FeedItem.find(1)

    see_element "#feed_item_#{feed_item_1.id}.unread"

    click "css=#feed_item_#{feed_item_1.id} .opener"
    see_element "#feed_item_#{feed_item_1.id}.read"

    refresh_and_wait
    wait_for_ajax
    dont_see_element "#feed_item_#{feed_item_1.id}"
  end
  
  it "click_feed_title_takes_you_to_feed_page" do
    feed_item_1 = FeedItem.find(1)
    feed1 = feed_item_1.feed
    see_element "#feed_link_for_feed_item_#{feed_item_1.id}"
    click_and_wait "css=#feed_link_for_feed_item_#{feed_item_1.id}"
    assert_match feed_url(feed1), get_location
    see_element "#feed_1"
  end
  
  it "displays an empty message when there are no feed items" do
    Tagging.delete_all
    FeedItem.delete_all

    open feed_items_path
    wait_for_ajax
  
    see_element "#feed_items .empty"
  end
  
  it "does not display an empty message when there are feed items" do
    dont_see_element "#feed_items .empty"
  end
end
