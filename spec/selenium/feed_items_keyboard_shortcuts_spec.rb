# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe "keyboard shortcuts" do
  fixtures :users, :feed_items, :feeds, :feed_item_contents

  before(:each) do
    ReadItem.delete_all
    login
    open feed_items_path
    wait_for_ajax
  end
  
  it "change_item" do
    feed_item_2, feed_item_1 = FeedItem.find(3, 4)

    dont_see_element "#feed_item_#{feed_item_1.id}.selected"
    assert_not_visible "css=#feed_item_#{feed_item_1.id} .body"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    assert_not_visible "css=#feed_item_#{feed_item_2.id} .body"

    key_press "css=body", "j"
    see_element "#feed_item_#{feed_item_1.id}.selected"
    assert_visible "css=#feed_item_#{feed_item_1.id} .body"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    assert_not_visible "css=#feed_item_#{feed_item_2.id} .body"

    key_press "css=body", "j"
    dont_see_element "#feed_item_#{feed_item_1.id}.selected"
    assert_not_visible "css=#feed_item_#{feed_item_1.id} .body"
    see_element "#feed_item_#{feed_item_2.id}.selected"
    assert_visible "css=#feed_item_#{feed_item_2.id} .body"

    key_press "css=body", "k"
    see_element "#feed_item_#{feed_item_1.id}.selected"
    assert_visible "css=#feed_item_#{feed_item_1.id} .body"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    assert_not_visible "css=#feed_item_#{feed_item_2.id} .body"

    key_press "css=body", "k"
    see_element "#feed_item_#{feed_item_1.id}.selected"
    assert_visible "css=#feed_item_#{feed_item_1.id} .body"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    assert_not_visible "css=#feed_item_#{feed_item_2.id} .body"
  end
  
  it "mark_read_unread" do
    feed_item_2, feed_item_1 = FeedItem.find(3, 4)

    dont_see_element "#feed_item_#{feed_item_1.id}.selected"
    dont_see_element "#feed_item_#{feed_item_1.id}.read"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    dont_see_element "#feed_item_#{feed_item_2.id}.read"

    key_press "css=body", "n"
    see_element "#feed_item_#{feed_item_1.id}.selected"
    dont_see_element "#feed_item_#{feed_item_1.id}.read"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    dont_see_element "#feed_item_#{feed_item_2.id}.read"

    key_press "css=body", "m"
    see_element "#feed_item_#{feed_item_1.id}.selected"
    see_element "#feed_item_#{feed_item_1.id}.read"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    dont_see_element "#feed_item_#{feed_item_2.id}.read"

    key_press "css=body", "m"
    see_element "#feed_item_#{feed_item_1.id}.selected"
    dont_see_element "#feed_item_#{feed_item_1.id}.read"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    dont_see_element "#feed_item_#{feed_item_2.id}.read"
  end
  
  it "open_close_moderation_panel " do
    feed_item_2, feed_item_1 = FeedItem.find(3, 4) 
 
    dont_see_element "#feed_item_#{feed_item_1.id}.selected" 
    assert_not_visible "css=#feed_item_#{feed_item_1.id} .moderation_panel"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected" 
    assert_not_visible "css=#feed_item_#{feed_item_2.id} .moderation_panel"
 
    key_press "css=body", "n" 
    see_element "#feed_item_#{feed_item_1.id}.selected" 
    assert_not_visible "css=#feed_item_#{feed_item_1.id} .moderation_panel"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected" 
    assert_not_visible "css=#feed_item_#{feed_item_2.id} .moderation_panel"
 
    key_press "css=body", "t" 
    see_element "#feed_item_#{feed_item_1.id}.selected" 
    assert_visible "css=#feed_item_#{feed_item_1.id} .moderation_panel"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected" 
    assert_not_visible "css=#feed_item_#{feed_item_2.id} .moderation_panel"
 
    key_press "css=body", "t" 
    see_element "#feed_item_#{feed_item_1.id}.selected" 
    assert_not_visible "css=#feed_item_#{feed_item_1.id} .moderation_panel"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    assert_not_visible "css=#feed_item_#{feed_item_2.id} .moderation_panel"
  end
  
  it "open_close_item" do
    feed_item_2, feed_item_1 = FeedItem.find(3, 4)

    dont_see_element "#feed_item_#{feed_item_1.id}.selected"
    assert_not_visible "css=#feed_item_#{feed_item_1.id} .body"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    assert_not_visible "css=#feed_item_#{feed_item_2.id} .body"

    key_press "css=body", "n"
    see_element "#feed_item_#{feed_item_1.id}.selected"
    assert_not_visible "css=#feed_item_#{feed_item_1.id} .body"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    assert_not_visible "css=#feed_item_#{feed_item_2.id} .body"

    key_press "css=body", "o"
    see_element "#feed_item_#{feed_item_1.id}.selected"
    assert_visible "css=#feed_item_#{feed_item_1.id} .body"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    assert_not_visible "css=#feed_item_#{feed_item_2.id} .body"

    key_press "css=body", "o"
    see_element "#feed_item_#{feed_item_1.id}.selected"
    assert_not_visible "css=#feed_item_#{feed_item_1.id} .body"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    assert_not_visible "css=#feed_item_#{feed_item_2.id} .body"
  end
  
  it "closes open items when opening an item" do
    feed_item_2, feed_item_1 = FeedItem.find(3, 4)

    dont_see_element "#feed_item_#{feed_item_1.id}.selected"
    assert_not_visible "css=#feed_item_#{feed_item_1.id} .body"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    assert_not_visible "css=#feed_item_#{feed_item_2.id} .body"

    key_press "css=body", "n"
    see_element "#feed_item_#{feed_item_1.id}.selected"
    assert_not_visible "css=#feed_item_#{feed_item_1.id} .body"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    assert_not_visible "css=#feed_item_#{feed_item_2.id} .body"

    key_press "css=body", "o"
    see_element "#feed_item_#{feed_item_1.id}.selected"
    assert_visible "css=#feed_item_#{feed_item_1.id} .body"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    assert_not_visible "css=#feed_item_#{feed_item_2.id} .body"

    key_press "css=body", "n"
    dont_see_element "#feed_item_#{feed_item_1.id}.selected"
    assert_visible "css=#feed_item_#{feed_item_1.id} .body"
    see_element "#feed_item_#{feed_item_2.id}.selected"
    assert_not_visible "css=#feed_item_#{feed_item_2.id} .body"

    key_press "css=body", "o"
    dont_see_element "#feed_item_#{feed_item_1.id}.selected"
    assert_not_visible "css=#feed_item_#{feed_item_1.id} .body"
    see_element "#feed_item_#{feed_item_2.id}.selected"
    assert_visible "css=#feed_item_#{feed_item_2.id} .body"
  end
  
  it "select_item" do
    feed_item_2, feed_item_1 = FeedItem.find(3, 4)

    dont_see_element "#feed_item_#{feed_item_1.id}.selected"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"

    key_press "css=body", "n"
    see_element "#feed_item_#{feed_item_1.id}.selected"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"

    key_press "css=body", "n"
    dont_see_element "#feed_item_#{feed_item_1.id}.selected"
    see_element "#feed_item_#{feed_item_2.id}.selected"

    key_press "css=body", "p"
    see_element "#feed_item_#{feed_item_1.id}.selected"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"

    key_press "css=body", "p"
    see_element "#feed_item_#{feed_item_1.id}.selected"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
  end
end
