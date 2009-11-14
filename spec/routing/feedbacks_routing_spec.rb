# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe FeedbacksController do
  describe "route generation" do
    it "should map { :controller => 'feedbacks', :action => 'index' } to /feedbacks" do
      route_for(:controller => "feedbacks", :action => "index").should == "/feedbacks"
    end
  
    it "should map { :controller => 'feedbacks', :action => 'new' } to /feedbacks/new" do
      route_for(:controller => "feedbacks", :action => "new").should == "/feedbacks/new"
    end
  end

  describe "route recognition" do
    it "should generate params { :controller => 'feedbacks', action => 'index' } from GET /feedbacks" do
      params_from(:get, "/feedbacks").should == {:controller => "feedbacks", :action => "index"}
    end
  
    it "should generate params { :controller => 'feedbacks', action => 'new' } from GET /feedbacks/new" do
      params_from(:get, "/feedbacks/new").should == {:controller => "feedbacks", :action => "new"}
    end
  
    it "should generate params { :controller => 'feedbacks', action => 'create' } from POST /feedbacks" do
      params_from(:post, "/feedbacks").should == {:controller => "feedbacks", :action => "create"}
    end
  end
end