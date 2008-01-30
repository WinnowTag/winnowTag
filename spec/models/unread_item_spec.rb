# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../spec_helper'

describe UnreadItem do
  def test_user_must_exist
    UnreadItem.new(:feed_item => FeedItem.find(1)).should_not be_valid
  end
  
  def test_feed_item_must_exist
    UnreadItem.new(:user => User.find(1)).should_not be_valid
  end
  
  def test_user_and_feed_item_existing_is_valid
    UnreadItem.new(:user => User.find(1), :feed_item => FeedItem.find(2)).should be_valid
  end
  
  def test_user_and_feed_item_must_be_unique
    UnreadItem.new(:user => User.find(1), :feed_item => FeedItem.find(1)).should_not be_valid
  end
end
