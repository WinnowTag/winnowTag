# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'

class UnreadItemTest < Test::Unit::TestCase
  fixtures :unread_items

  def test_user_must_exist
    assert_invalid UnreadItem.new(:feed_item => FeedItem.find(1))
  end
  
  def test_feed_item_must_exist
    assert_invalid UnreadItem.new(:user => User.find(1))
  end
  
  def test_user_and_feed_item_existing_is_valid
    assert_valid UnreadItem.new(:user => User.find(1), :feed_item => FeedItem.find(2))
  end
  
  def test_user_and_feed_item_must_be_unique
    assert_invalid UnreadItem.new(:user => User.find(1), :feed_item => FeedItem.find(1))
  end
end
