# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe FeedItemTextIndex do
  after(:each) do
    # Have to manually delete since it is a MyISAM table
    FeedItemTextIndex.delete_all
  end
  
  it "should strip html" do
    index = FeedItemTextIndex.create!(:feed_item_id => 1, :content => "<p>this is content</p>")
    index.content.should == "this is content"
  end
end
