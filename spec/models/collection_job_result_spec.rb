# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
require File.dirname(__FILE__) + '/../spec_helper'

describe CollectionJobResult do
  describe "feed_title" do 
    it "displays 'Unknown Feed' when no feed is assigned" do
      collection_job_result = CollectionJobResult.new
      collection_job_result.feed_title.should == "Unknown Feed"
    end
    
    it "displays the feeds title if the feed has a title" do 
      feed = mock_model(Feed, :title => "Feed Title")
      collection_job_result = CollectionJobResult.new
      collection_job_result.stub!(:feed).and_return(feed)
      collection_job_result.feed_title.should == feed.title
    end
    
    it "displays the feeds url if the feed has no title but has a url" do 
      feed = mock_model(Feed, :title => nil, :url => "http://feed.example.com")
      collection_job_result = CollectionJobResult.new
      collection_job_result.stub!(:feed).and_return(feed)
      collection_job_result.feed_title.should == feed.url
    end
    
    it "displays the feeds url if the feed has a blank title but has a url" do 
      feed = mock_model(Feed, :title => "", :url => "http://feed.example.com")
      collection_job_result = CollectionJobResult.new
      collection_job_result.stub!(:feed).and_return(feed)
      collection_job_result.feed_title.should == feed.url
    end
  end
end