# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../spec_helper'

describe ReadItem do
  fixtures :feed_items, :users
  
  it "user_must_exist" do
    ReadItem.new(:feed_item => FeedItem.find(1)).should_not be_valid
  end
  
  it "feed_item_must_exist" do
    ReadItem.new(:user => User.find(1)).should_not be_valid
  end
  
  it "user_and_feed_item_existing_is_valid" do
    ReadItem.new(:user => User.find(1), :feed_item => FeedItem.find(2)).should be_valid
  end
  
  it "user_and_feed_item_must_be_unique" do
    ReadItem.create!(:user => User.find(1), :feed_item => FeedItem.find(1))
    ReadItem.new(:user => User.find(1), :feed_item => FeedItem.find(1)).should_not be_valid
  end
end
