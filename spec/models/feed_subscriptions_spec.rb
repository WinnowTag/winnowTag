# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe FeedSubscription do
  it "should enforce unique user_id/feed_id pairs" do
    FeedSubscription.create! :user_id => 100, :feed_id => 100
    lambda { FeedSubscription.create! :user_id => 100, :feed_id => 100 }.should raise_error(ActiveRecord::StatementInvalid)
  end
end