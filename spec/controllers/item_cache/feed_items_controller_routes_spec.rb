# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../../spec_helper'

describe ItemCache::FeedsController do
  describe "route generation" do
    it "should map { :controller => 'feed_items', :action => 'index', :feed_id => 1 } to /item_cache/feeds/1/feed_items" do 
      route_for(:controller => "item_cache/feed_items", :action => "index", :feed_id => 1).should == "/item_cache/feeds/1/feed_items"
    end
    
    it "should map { :controller => 'feed_items', :action => 'index' } to /item_cache/feed_items" do
      route_for(:controller => "item_cache/feed_items", :action => "index").should == "/item_cache/feed_items"
    end
  
    it "should map { :controller => 'feed_items', :action => 'show', :id => 1 } to /item_cache/feed_items/1" do
      route_for(:controller => "item_cache/feed_items", :action => "show", :id => 1).should == "/item_cache/feed_items/1"
    end
    
    it "should map { :controller => 'feed_items', :action => 'update', :id => 1} to /item_cache/feed_items/1" do
      route_for(:controller => "item_cache/feed_items", :action => "update", :id => 1).should == "/item_cache/feed_items/1"
    end
  
    it "should map { :controller => 'feed_items', :action => 'destroy', :id => 1} to /item_cache/feed_items/1" do
      route_for(:controller => "item_cache/feed_items", :action => "destroy", :id => 1).should == "/item_cache/feed_items/1"
    end
  end

  describe "route recognition" do

    it "should generate params { :controller => 'feed_items', action => 'create', :feed_id => 1 } from POST /item_cache/feeds/1/feed_items" do
      params_from(:post, "/item_cache/feeds/1/feed_items").should == {:controller => "item_cache/feed_items", :action => "create", :feed_id => "1"}
    end
    
    it "should generate params { :controller => 'feed_items', action => 'index' } from GET /feed_items" do
      params_from(:get, "/item_cache/feed_items").should == {:controller => "item_cache/feed_items", :action => "index"}
    end
  
    it "should generate params { :controller => 'feed_items', action => 'create' } from POST /feed_items" do
      params_from(:post, "/item_cache/feed_items").should == {:controller => "item_cache/feed_items", :action => "create"}
    end
  
    it "should generate params { :controller => 'feed_items', action => 'show', id => '1' } from GET /feed_items/1" do
      params_from(:get, "/item_cache/feed_items/1").should == {:controller => "item_cache/feed_items", :action => "show", :id => "1"}
    end
  
    it "should generate params { :controller => 'feed_items', action => 'update', id => '1' } from PUT /feed_items/1" do
      params_from(:put, "/item_cache/feed_items/1").should == {:controller => "item_cache/feed_items", :action => "update", :id => "1"}
    end
  
    it "should generate params { :controller => 'feed_items', action => 'destroy', id => '1' } from DELETE /feed_items/1" do
      params_from(:delete, "/item_cache/feed_items/1").should == {:controller => "item_cache/feed_items", :action => "destroy", :id => "1"}
    end
  end
end