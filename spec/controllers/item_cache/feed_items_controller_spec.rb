# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe ItemCache::FeedItemsController do
  fixtures :feed_items, :feeds
  
  before(:each) do
    @controller.stub!(:hmac_authenticated?).and_return(true)
  end
  
  describe "POST to /feeds/1/feed_items" do
    before(:each) do
      @atom = mock('atom')
      @feed = mock_model(Feed)
      @item = mock_model(FeedItem)
      
      feed_items = mock('feed_items')
      feed_items.should_receive(:find_or_create_from_atom).with(@atom).and_return(@item)
      
      @feed.should_receive(:feed_items).and_return(feed_items)
      Feed.should_receive(:find).with("1").and_return(@feed)
    end
    
    it "should respond with 201" do
      post :create, :feed_id => "1", :atom => @atom
      response.code.should == "201"
    end
    
    it "should set the location" do
      post :create, :feed_id => "1", :atom => @atom
      response.headers['Location'].should == item_cache_feed_item_url(@item)
    end
  end
    
  describe "POST to /feeds/1/feed_items without valid credentials" do
    it "should return 401 Authentication Required" do
      @controller.should_receive(:hmac_authenticated?).and_return(false)
      post :create, :feed_id => "1", :atom => @atom
      response.code.should == "401"
    end
  end
  
  describe "PUT to /feeds/1/feed_items/11" do
    before(:each) do
      @before_count = Feed.count
      @atom = Atom::Entry.new do |e|
        e.title = "Item Title"
        e.id = "urn:peerworks.org:feed_item#1"
        e.links << Atom::Link.new(:rel => 'self', :href => 'http://collector.org/1')
        e.links << Atom::Link.new(:rel => 'alternate', :href => 'http://collector.org/1')
      end
      put "update", :id => 1, :feed_id => 1, :atom => @atom
    end
    
    it "should update the feed item" do
      FeedItem.find(1).title.should == 'Item Title'
    end
    
    it "should respond with 200" do
      response.code.should == "200"
    end
    
    it "should not create a new item" do
      Feed.count.should == @before_count
    end
  end
  
  describe "PUT to /feed_items/1" do
    before(:each) do
      @before_count = Feed.count
      @atom = Atom::Entry.new do |e|
        e.title = "Item Title"
        e.id = "urn:peerworks.org:feed_item#1"
        e.links << Atom::Link.new(:rel => 'self', :href => 'http://collector.org/1')
        e.links << Atom::Link.new(:rel => 'alternate', :href => 'http://collector.org/1')
      end
      put "update", :id => 1, :atom => @atom
    end
    
    it "should update the feed item" do
      FeedItem.find(1).title.should == 'Item Title'
    end
    
    it "should respond with 200" do
      response.code.should == "200"
    end
    
    it "should not create a new item" do
      Feed.count.should == @before_count
    end
  end
  
  describe "PUT to /feed_items/1 with wrong id in entry" do
    before(:each) do
      @before_count = Feed.count
      @atom = Atom::Entry.new do |e|
        e.title = "Item Title"
        e.id = "urn:peerworks.org:feed_item#2"
        e.links << Atom::Link.new(:rel => 'self', :href => 'http://collector.org/1')
        e.links << Atom::Link.new(:rel => 'alternate', :href => 'http://collector.org/1')
      end
      put "update", :id => 1, :atom => @atom
    end
    
    it "should not update the entry" do
      FeedItem.find(1).title.should_not == 'Item Title'
    end
    
    it "should respond with 412" do
      response.code.should == "412"
    end
  end
    
  describe "DELETE to /feeds/1/feed_items/122" do
    it "should delete the feed item" do
      item = mock_model(FeedItem)
      item.should_receive(:destroy)
      FeedItem.should_receive(:find).with("122").and_return(item)
      delete "destroy", :feed_id => 1, :id => 122
    end
  end
  
  describe "DELETE to /feed_items/122" do
    it "should delete the feed item" do
      item = mock_model(FeedItem)
      item.should_receive(:destroy)
      FeedItem.should_receive(:find).with("122").and_return(item)
      delete "destroy", :id => 122
    end
  end
end
