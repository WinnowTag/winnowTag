# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe ItemCache::FeedsController do
  describe "route generation" do
    it "should map { :controller => 'feeds', :action => 'update', :id =>'urn:uuid:blah'} to /item_cache/feeds/urn:uuid:blah" do
      route_for(:controller => "item_cache/feeds", :action => "update", :id =>'urn:uuid:blah').should == { :path => "/item_cache/feeds/urn:uuid:blah", :method => :put }
    end
  
    it "should map { :controller => 'feeds', :action => 'destroy', :id =>'urn:uuid:blah'} to /item_cache/feeds/urn:uuid:blah" do
      route_for(:controller => "item_cache/feeds", :action => "destroy", :id =>'urn:uuid:blah').should == { :path => "/item_cache/feeds/urn:uuid:blah", :method => :delete }
    end
  end

  describe "route recognition" do
    it "should generate params { :controller => 'feeds', action => 'create' } from POST /feeds" do
      params_from(:post, "/item_cache/feeds").should == {:controller => "item_cache/feeds", :action => "create"}
    end

    it "should generate params { :controller => 'feeds', action => 'update', id => '1' } from PUT /feeds/urn:uuid:blah" do
      params_from(:put, "/item_cache/feeds/urn:uuid:blah").should == {:controller => "item_cache/feeds", :action => "update", :id => "urn:uuid:blah"}
    end
  
    it "should generate params { :controller => 'feeds', action => 'destroy', id => '1' } from DELETE /feeds/urn:uuid:blah" do
      params_from(:delete, "/item_cache/feeds/urn:uuid:blah").should == {:controller => "item_cache/feeds", :action => "destroy", :id => "urn:uuid:blah"}
    end
  end
end