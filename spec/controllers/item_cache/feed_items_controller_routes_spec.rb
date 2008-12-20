# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe ItemCache::FeedsController do
  describe "route generation" do
    it "should map { :controller => 'feed_items', :action => 'index', :feed_id => urn:uuid:feed1 } to /item_cache/feeds/urn:uuid:feed1/feed_items" do 
      route_for(:controller => "item_cache/feed_items", :action => "index", :feed_id => 'urn:uuid:feed1').should == "/item_cache/feeds/urn:uuid:feed1/feed_items"
    end
    
    it "should map { :controller => 'feed_items', :action => 'index' } to /item_cache/feed_items" do
      route_for(:controller => "item_cache/feed_items", :action => "index").should == "/item_cache/feed_items"
    end
  
    it "should map { :controller => 'feed_items', :action => 'show', :id => urn:uuid:item1 } to /item_cache/feed_items/urn:uuid:item1" do
      route_for(:controller => "item_cache/feed_items", :action => "show", :id => 'urn:uuid:item1').should == "/item_cache/feed_items/urn:uuid:item1"
    end
    
    it "should map { :controller => 'feed_items', :action => 'update', :id => urn:uuid:item1} to /item_cache/feed_items/urn:uuid:item1" do
      route_for(:controller => "item_cache/feed_items", :action => "update", :id => 'urn:uuid:item1').should == "/item_cache/feed_items/urn:uuid:item1"
    end
  
    it "should map { :controller => 'feed_items', :action => 'destroy', :id => urn:uuid:item1} to /item_cache/feed_items/urn:uuid:item1" do
      route_for(:controller => "item_cache/feed_items", :action => "destroy", :id => 'urn:uuid:item1').should == "/item_cache/feed_items/urn:uuid:item1"
    end
    
    it "should map legacy ids" do
      route_for(:controller => "item_cache/feed_items", :action => "show", :id => 'urn:peerworks.org:entry#1').should == "/item_cache/feed_items/urn:peerworks.org:entry%231"
    end
  end

  describe "route recognition" do

    it "should generate params { :controller => 'feed_items', action => 'create', :feed_id => 'urn:uuid:feed1' } from POST /item_cache/feeds/urn:uuid:feed1/feed_items" do
      params_from(:post, "/item_cache/feeds/urn:uuid:feed1/feed_items").should == {:controller => "item_cache/feed_items", :action => "create", :feed_id => "urn:uuid:feed1"}
    end
    
    it "should generate params { :controller => 'feed_items', action => 'index' } from GET /feed_items" do
      params_from(:get, "/item_cache/feed_items").should == {:controller => "item_cache/feed_items", :action => "index"}
    end
  
    it "should generate params { :controller => 'feed_items', action => 'create' } from POST /feed_items" do
      params_from(:post, "/item_cache/feed_items").should == {:controller => "item_cache/feed_items", :action => "create"}
    end
  
    it "should generate params { :controller => 'feed_items', action => 'show', id => 'urn:uuid:item1' } from GET /feed_items/urn:uuid:item1" do
      params_from(:get, "/item_cache/feed_items/urn:uuid:item1").should == {:controller => "item_cache/feed_items", :action => "show", :id => "urn:uuid:item1"}
    end
  
    it "should generate params { :controller => 'feed_items', action => 'update', id => 'urn:uuid:item1' } from PUT /feed_items/urn:uuid:item1" do
      params_from(:put, "/item_cache/feed_items/urn:uuid:item1").should == {:controller => "item_cache/feed_items", :action => "update", :id => "urn:uuid:item1"}
    end
  
    it "should generate params { :controller => 'feed_items', action => 'destroy', id => 'urn:uuid:item1' } from DELETE /feed_items/urn:uuid:item1" do
      params_from(:delete, "/item_cache/feed_items/urn:uuid:item1").should == {:controller => "item_cache/feed_items", :action => "destroy", :id => "urn:uuid:item1"}
    end
    
    it "should map legacy ids" do
      params_from(:get, "/item_cache/feed_items/urn:peerworks.org:entry%231").should == {:controller => "item_cache/feed_items", :action => "show", :id => 'urn:peerworks.org:entry#1'}
    end
    
    it "should map legacy ids" do
      params_from(:post, "/item_cache/feeds/urn:peerworks.org:feed%231/feed_items").should == {:controller => "item_cache/feed_items", :action => "create", :feed_id => 'urn:peerworks.org:feed#1'}
    end
    
    it "should map legacy ids" do
      params_from(:get, "/item_cache/feeds/urn:peerworks.org:feed%231/feed_items/urn:peerworks.org:entry%231").should == 
                      {:controller => "item_cache/feed_items", :action => "show", :feed_id => 'urn:peerworks.org:feed#1', :id => 'urn:peerworks.org:entry#1'}
    end
  end
end