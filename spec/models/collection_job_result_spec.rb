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
      feed = mock_model(Feed, :title => nil, :via => "http://feed.example.com")
      collection_job_result = CollectionJobResult.new
      collection_job_result.stub!(:feed).and_return(feed)
      collection_job_result.feed_title.should == feed.via
    end
    
    it "displays the feeds url if the feed has a blank title but has a url" do 
      feed = mock_model(Feed, :title => "", :via => "http://feed.example.com")
      collection_job_result = CollectionJobResult.new
      collection_job_result.stub!(:feed).and_return(feed)
      collection_job_result.feed_title.should == feed.via
    end
    
    it "tries to get the resource from the collector if it can't find the feed" do
      feed = mock_model(Remote::Feed, :title => "Remote Feed Title", :via => "http://feed.example.com")
      Remote::Feed.should_receive(:find).with(55).and_return(feed)
      collection_job_result = CollectionJobResult.new(:feed_id => 55)
      collection_job_result.feed_title.should == feed.title
    end
  end
end