# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require File.dirname(__FILE__) + '/../../spec_helper'

describe ItemCache::FeedItemsController do
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
      @feed_item = Generate.feed_item!
      
      @before_count = Feed.count
      atom = Atom::Entry.new do |e|
        e.title = "Item Title"
        e.id = @feed_item.uri
        e.links << Atom::Link.new(:rel => 'self', :href => 'http://collector.org/1')
        e.links << Atom::Link.new(:rel => 'alternate', :href => 'http://collector.org/1')
      end
      put "update", :id => @feed_item.uri, :feed_id => "urn:uuid:feed1", :atom => atom
      @feed_item.reload
    end
    
    it "should update the feed item" do
      @feed_item.title.should == 'Item Title'
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
      @feed_item = Generate.feed_item!
      
      @before_count = Feed.count
      atom = Atom::Entry.new do |e|
        e.title = "Item Title"
        e.id = @feed_item.uri
        e.links << Atom::Link.new(:rel => 'self', :href => 'http://collector.org/1')
        e.links << Atom::Link.new(:rel => 'alternate', :href => 'http://collector.org/1')
      end
      put "update", :id => @feed_item.uri, :atom => atom
      @feed_item.reload
    end
    
    it "should update the feed item" do
      @feed_item.title.should == 'Item Title'
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
      @feed_item = Generate.feed_item!

      @before_count = Feed.count
      @atom = Atom::Entry.new do |e|
        e.title = "Item Title"
        e.id = "#{@feed_item.uri}Wrong"
        e.links << Atom::Link.new(:rel => 'self', :href => 'http://collector.org/1')
        e.links << Atom::Link.new(:rel => 'alternate', :href => 'http://collector.org/1')
      end
      put "update", :id => @feed_item.uri, :atom => @atom
      @feed_item.reload
    end
    
    it "should not update the entry" do
      @feed_item.title.should_not == 'Item Title'
    end
    
    it "should respond with 412" do
      response.code.should == "412"
    end
  end
  
  describe "PUT to non-existent item does nothing" do
    before(:each) do
      @feed_item = Generate.feed_item!

      @before_count = FeedItem.count
      @atom = Atom::Entry.new do |e|
        e.title = "Item Title"
        e.id = "#{@feed_item.uri}Wrong"
        e.links << Atom::Link.new(:rel => 'self', :href => 'http://collector.org/1')
        e.links << Atom::Link.new(:rel => 'alternate', :href => 'http://collector.org/1')
      end
      put "update", :id => "urn:uuid:nonexistant", :atom => @atom
    end
    
    it "not add an item" do
      FeedItem.count.should == @before_count
    end
    
    it "should respond with 202" do
      response.code.should == "202"
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
