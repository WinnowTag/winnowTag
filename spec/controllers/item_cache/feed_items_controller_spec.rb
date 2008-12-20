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
  
  describe "POST to /feeds/urn:uuid:feed1/feed_items" do
    before(:each) do
      @atom = mock('atom', :uri => 'urn:uuid:item222')
      @feed = mock_model(Feed)
      @item = mock_model(FeedItem, :uri => @atom.uri)
      
      feed_items = mock('feed_items')
      feed_items.should_receive(:find_or_create_from_atom).with(@atom).and_return(@item)
      
      @feed.should_receive(:feed_items).and_return(feed_items)
      Feed.should_receive(:find_by_uri).with("urn:uuid:feed1").and_return(@feed)
    end
    
    it "should respond with 201" do
      post :create, :feed_id => "urn:uuid:feed1", :atom => @atom
      response.code.should == "201"
    end
    
    it "should set the location" do
      post :create, :feed_id => "urn:uuid:feed1", :atom => @atom
      response.headers['Location'].should match(/\/feed_items\/urn:uuid:item222/)
    end
  end
    
  describe "POST to /feeds/urn:uuid:feed1/feed_items without valid credentials" do
    it "should return 401 Authentication Required" do
      @controller.should_receive(:hmac_authenticated?).and_return(false)
      post :create, :feed_id => "urn:uuid:feed1", :atom => @atom
      response.code.should == "401"
    end
  end
  
  describe "PUT to /feeds/urn:uuid:feed1/feed_items/urn:uuid:item1" do
    before(:each) do
      @before_count = Feed.count
      @atom = Atom::Entry.new do |e|
        e.title = "Item Title"
        e.id = "urn:uuid:item1"
        e.links << Atom::Link.new(:rel => 'self', :href => 'http://collector.org/1')
        e.links << Atom::Link.new(:rel => 'alternate', :href => 'http://collector.org/1')
      end
      put "update", :id => "urn:uuid:item1", :feed_id => "urn:uuid:feed1", :atom => @atom
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
  
  describe "PUT to /feed_items/urn:uuid:item1" do
    before(:each) do
      @before_count = Feed.count
      @atom = Atom::Entry.new do |e|
        e.title = "Item Title"
        e.id = "urn:uuid:item1"
        e.links << Atom::Link.new(:rel => 'self', :href => 'http://collector.org/1')
        e.links << Atom::Link.new(:rel => 'alternate', :href => 'http://collector.org/1')
      end
      put "update", :id => "urn:uuid:item1", :atom => @atom
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
  
  describe "PUT to /feed_items/urn:uuid:item1 with wrong id in entry" do
    before(:each) do
      @before_count = Feed.count
      @atom = Atom::Entry.new do |e|
        e.title = "Item Title"
        e.id = "urn:uuid:item2"
        e.links << Atom::Link.new(:rel => 'self', :href => 'http://collector.org/1')
        e.links << Atom::Link.new(:rel => 'alternate', :href => 'http://collector.org/1')
      end
      put "update", :id => "urn:uuid:item1", :atom => @atom
    end
    
    it "should not update the entry" do
      FeedItem.find(1).title.should_not == 'Item Title'
    end
    
    it "should respond with 412" do
      response.code.should == "412"
    end
  end
    
  describe "DELETE to /feeds/urn:uuid:feed1/feed_items/urn:uuid:item122" do
    it "should delete the feed item" do
      item = mock_model(FeedItem)
      item.should_receive(:destroy)
      FeedItem.should_receive(:find_by_uri).with("urn:uuid:item122").and_return(item)
      delete "destroy", :feed_id => "urn:uuid:feed1", :id => "urn:uuid:item122"
    end
  end
  
  describe "DELETE to /feed_items/urn:uuid:item122" do
    it "should delete the feed item" do
      item = mock_model(FeedItem)
      item.should_receive(:destroy)
      FeedItem.should_receive(:find_by_uri).with("urn:uuid:item122").and_return(item)
      delete "destroy", :id => "urn:uuid:item122"
    end
  end
end
