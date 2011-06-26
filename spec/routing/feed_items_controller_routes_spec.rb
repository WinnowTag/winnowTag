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

require File.dirname(__FILE__) + '/../spec_helper'

describe ItemCache::FeedsController do
  describe "route generation" do
    it "should map { :controller => 'feed_items', :action => 'update', :id => urn:uuid:item1} to /item_cache/feed_items/urn:uuid:item1" do
      route_for(:controller => "item_cache/feed_items", :action => "update", :id => 'urn:uuid:item1').should == {:path => "/item_cache/feed_items/urn:uuid:item1", :method => :put}
    end
  
    it "should map { :controller => 'feed_items', :action => 'destroy', :id => urn:uuid:item1} to /item_cache/feed_items/urn:uuid:item1" do
      route_for(:controller => "item_cache/feed_items", :action => "destroy", :id => 'urn:uuid:item1').should == {:path => "/item_cache/feed_items/urn:uuid:item1", :method => :delete}
    end
    
    it "should map legacy ids" do
      route_for(:controller => "item_cache/feed_items", :action => "update", :id => 'urn:peerworks.org:entry#1').should == { :path => "/item_cache/feed_items/urn:peerworks.org:entry%231", :method => :put }
    end
  end

  describe "route recognition" do
    it "should generate params { :controller => 'feed_items', action => 'create', :feed_id => 'urn:uuid:feed1' } from POST /item_cache/feeds/urn:uuid:feed1/feed_items" do
      params_from(:post, "/item_cache/feeds/urn:uuid:feed1/feed_items").should == {:controller => "item_cache/feed_items", :action => "create", :feed_id => "urn:uuid:feed1"}
    end

    it "should generate params { :controller => 'feed_items', action => 'create' } from POST /feed_items" do
      params_from(:post, "/item_cache/feed_items").should == {:controller => "item_cache/feed_items", :action => "create"}
    end

    it "should generate params { :controller => 'feed_items', action => 'update', id => 'urn:uuid:item1' } from PUT /feed_items/urn:uuid:item1" do
      params_from(:put, "/item_cache/feed_items/urn:uuid:item1").should == {:controller => "item_cache/feed_items", :action => "update", :id => "urn:uuid:item1"}
    end
  
    it "should generate params { :controller => 'feed_items', action => 'destroy', id => 'urn:uuid:item1' } from DELETE /feed_items/urn:uuid:item1" do
      params_from(:delete, "/item_cache/feed_items/urn:uuid:item1").should == {:controller => "item_cache/feed_items", :action => "destroy", :id => "urn:uuid:item1"}
    end
    
    it "should map legacy ids" do
      params_from(:put, "/item_cache/feed_items/urn:peerworks.org:entry%231").should == {:controller => "item_cache/feed_items", :action => "update", :id => 'urn:peerworks.org:entry#1'}
    end
    
    it "should map legacy ids" do
      params_from(:post, "/item_cache/feeds/urn:peerworks.org:feed%231/feed_items").should == {:controller => "item_cache/feed_items", :action => "create", :feed_id => 'urn:peerworks.org:feed#1'}
    end
    
    it "should map legacy ids" do
      params_from(:put, "/item_cache/feeds/urn:peerworks.org:feed%231/feed_items/urn:peerworks.org:entry%231").should == 
                      {:controller => "item_cache/feed_items", :action => "update", :feed_id => 'urn:peerworks.org:feed#1', :id => 'urn:peerworks.org:entry#1'}
    end
  end
end