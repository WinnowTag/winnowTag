# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe ItemCache::FeedsController do
  fixtures :feeds
  before(:each) do
    @controller.stub!(:hmac_authenticated?).and_return(true)
  end
  
  describe "POST Atom::Entry to /item_cache/feeds" do
    before(:each) do
      @before_count = Feed.count
      @atom = Atom::Entry.new do |e|
        e.title = "Feed Title"
        e.id = "urn:peerworks.org:feed#222"
        e.links << Atom::Link.new(:rel => 'self', :href => 'http://collector.org/222')
      end
      
      @feed = mock_model(Feed, :to_atom_entry => 'atom entry')
      Feed.stub!(:find_or_create_from_atom_entry).and_return(@feed)
    end
    
    it "should set the location header" do
      post 'create', :atom => @atom
      response.headers['Location'].should == item_cache_feed_url(@feed)
    end
    
    it "should have 201 as the status code" do
      post 'create', :atom => @atom
      response.code.should == "201"
    end
  end
  
  describe "POST Atom::Entry to /item_cache/feeds without valid credentials" do
    it "should return 401 Autentication Required" do
      @controller.should_receive(:hmac_authenticated?).and_return(false)
      post :create, :atom => @atom
      response.code.should == "401"
    end
  end
  
  describe "PUT Atom::Entry to /item_cache/feeds/1" do
    before(:each) do
      @before_count = Feed.count
      @atom = Atom::Entry.new do |e|
        e.title = "Feed Title"
        e.id = "urn:uuid:feed1"
        e.links << Atom::Link.new(:rel => 'self', :href => 'http://collector.org/222')
      end
    end
    
    it "should update the feed" do
      put :update, :id => @atom.id, :atom => @atom
      Feed.find(1).title.should == 'Feed Title'
    end
    
    it "should not add a new feed" do
      put :update, :id => @atom.id, :atom => @atom
      Feed.count.should == @before_count
    end
    
    it "should render 200" do
      put :update, :id => @atom.id, :atom => @atom
      response.code.should == "200"
    end
    
    describe "with a different id" do
      it "should not update the feed" do
        put :update, :id => Feed.find(2).uri, :atom => @atom
        Feed.find(2).title.should_not == 'Feed Title'
      end
      
      it "should return a 412 (Precondition Failed) error" do
        put :update, :id => Feed.find(2).uri, :atom => @atom
        response.code.should == "412"
      end
    end
  end
    
  describe "DELETE to /item_cache/feeds/1" do
    it "should delete the feed" do
      feed = mock_model(Feed)
      feed.should_receive(:destroy)
      Feed.should_receive(:find_by_uri).with("urn:uuid:blah").and_return(feed)
      delete :destroy, :id => "urn:uuid:blah"
    end    
  end
end
