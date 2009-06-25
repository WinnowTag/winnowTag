# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe TaggingsController do
  describe "route generation" do
    it "should map { :controller => 'taggings', :action => 'create' } to /taggings" do
      route_for(:controller => "taggings", :action => "create").should == { :path => "/taggings", :method => :post }
    end

    it "should map { :controller => 'taggings', :action => 'destroy' } to /taggings" do
      route_for(:controller => "taggings", :action => "destroy").should == { :path => "/taggings", :method => :delete }
    end
  end

  describe "route recognition" do
    it "should generate params { :controller => 'taggings', action => 'create' } from POST /taggings" do
      params_from(:post, "/taggings").should == { :controller => "taggings", :action => "create" }
    end

    it "should generate params { :controller => 'taggings', action => 'destroy' } from DELETE /taggings" do
      params_from(:delete, "/taggings").should == { :controller => "taggings", :action => "destroy" }
    end
  end
end