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