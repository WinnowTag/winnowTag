# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../spec_helper'

describe UnreadItemObserver do
  fixtures :users
  it "should create UnreadItem entries for each user" do
    FeedItem.with_observers(:unread_item_observer) do
      @before_count = UnreadItem.count
      FeedItem.create(valid_feed_item_attributes)
      UnreadItem.count.should == (@before_count + User.count)
    end
  end
end
