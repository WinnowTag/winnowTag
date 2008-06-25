# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe ItemCache::FeedsController do
  describe "route generation" do

    it "should map { :controller => 'feeds', :action => 'index' } to /item_cache/feeds" do
      route_for(:controller => "item_cache/feeds", :action => "index").should == "/item_cache/feeds"
    end
  
    it "should map { :controller => 'feeds', :action => 'new' } to /item_cache/feeds/new" do
      route_for(:controller => "item_cache/feeds", :action => "new").should == "/item_cache/feeds/new"
    end
  
    it "should map { :controller => 'feeds', :action => 'show', :id => 1 } to /item_cache/feeds/1" do
      route_for(:controller => "item_cache/feeds", :action => "show", :id => 1).should == "/item_cache/feeds/1"
    end
  
    it "should map { :controller => 'feeds', :action => 'edit', :id => 1 } to /item_cache/feeds/1<%= resource_edit_path %>" do
      route_for(:controller => "item_cache/feeds", :action => "edit", :id => 1).should == "/item_cache/feeds/1/edit"
    end
  
    it "should map { :controller => 'feeds', :action => 'update', :id => 1} to /item_cache/feeds/1" do
      route_for(:controller => "item_cache/feeds", :action => "update", :id => 1).should == "/item_cache/feeds/1"
    end
  
    it "should map { :controller => 'feeds', :action => 'destroy', :id => 1} to /item_cache/feeds/1" do
      route_for(:controller => "item_cache/feeds", :action => "destroy", :id => 1).should == "/item_cache/feeds/1"
    end
  end

  describe "route recognition" do

    it "should generate params { :controller => 'feeds', action => 'index' } from GET /feeds" do
      params_from(:get, "/item_cache/feeds").should == {:controller => "item_cache/feeds", :action => "index"}
    end
  
    it "should generate params { :controller => 'feeds', action => 'new' } from GET /feeds/new" do
      params_from(:get, "/item_cache/feeds/new").should == {:controller => "item_cache/feeds", :action => "new"}
    end
  
    it "should generate params { :controller => 'feeds', action => 'create' } from POST /feeds" do
      params_from(:post, "/item_cache/feeds").should == {:controller => "item_cache/feeds", :action => "create"}
    end
  
    it "should generate params { :controller => 'feeds', action => 'show', id => '1' } from GET /feeds/1" do
      params_from(:get, "/item_cache/feeds/1").should == {:controller => "item_cache/feeds", :action => "show", :id => "1"}
    end
  
    it "should generate params { :controller => 'feeds', action => 'edit', id => '1' } from GET /feeds/1;edit" do
      params_from(:get, "/item_cache/feeds/1/edit").should == {:controller => "item_cache/feeds", :action => "edit", :id => "1"}
    end
  
    it "should generate params { :controller => 'feeds', action => 'update', id => '1' } from PUT /feeds/1" do
      params_from(:put, "/item_cache/feeds/1").should == {:controller => "item_cache/feeds", :action => "update", :id => "1"}
    end
  
    it "should generate params { :controller => 'feeds', action => 'destroy', id => '1' } from DELETE /feeds/1" do
      params_from(:delete, "/item_cache/feeds/1").should == {:controller => "item_cache/feeds", :action => "destroy", :id => "1"}
    end
  end
end