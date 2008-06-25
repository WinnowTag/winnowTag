# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe TextIndexingObserver do
  after(:each) do
    FeedItemTextIndex.delete_all
  end
  
  it "should create entry in full text index when item is created" do
    FeedItem.with_observers(:text_indexing_observer) do
      count = FeedItemTextIndex.count
      item = FeedItem.new(:title => 'test', :link => 'http://example.com', 
                          :content => FeedItemContent.new(:content => "This is item content"))
      item.id = 23
      item.save!
      FeedItemTextIndex.count.should == (count + 1)
      
      item.text_index.content.should == 'test This is item content'
    end
  end
end