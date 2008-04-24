require File.dirname(__FILE__) + '/../spec_helper'

describe FeedbacksController do
  describe "route generation" do

    it "should map { :controller => 'feedbacks', :action => 'index' } to /feedbacks" do
      route_for(:controller => "feedbacks", :action => "index").should == "/feedbacks"
    end
  
    it "should map { :controller => 'feedbacks', :action => 'new' } to /feedbacks/new" do
      route_for(:controller => "feedbacks", :action => "new").should == "/feedbacks/new"
    end
  
    it "should map { :controller => 'feedbacks', :action => 'edit', :id => 1 } to /feedbacks/1/edit" do
      route_for(:controller => "feedbacks", :action => "edit", :id => 1).should == "/feedbacks/1/edit"
    end
  
    it "should map { :controller => 'feedbacks', :action => 'update', :id => 1} to /feedbacks/1" do
      route_for(:controller => "feedbacks", :action => "update", :id => 1).should == "/feedbacks/1"
    end
  
    it "should map { :controller => 'feedbacks', :action => 'destroy', :id => 1} to /feedbacks/1" do
      route_for(:controller => "feedbacks", :action => "destroy", :id => 1).should == "/feedbacks/1"
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
  
    it "should generate params { :controller => 'feedbacks', action => 'edit', id => '1' } from GET /feedbacks/1;edit" do
      params_from(:get, "/feedbacks/1/edit").should == {:controller => "feedbacks", :action => "edit", :id => "1"}
    end
  
    it "should generate params { :controller => 'feedbacks', action => 'update', id => '1' } from PUT /feedbacks/1" do
      params_from(:put, "/feedbacks/1").should == {:controller => "feedbacks", :action => "update", :id => "1"}
    end
  
    it "should generate params { :controller => 'feedbacks', action => 'destroy', id => '1' } from DELETE /feedbacks/1" do
      params_from(:delete, "/feedbacks/1").should == {:controller => "feedbacks", :action => "destroy", :id => "1"}
    end
  end
end