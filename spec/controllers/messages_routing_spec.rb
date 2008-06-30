# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe MessagesController do
  describe "route generation" do

    it "should map { :controller => 'messages', :action => 'index' } to /messages" do
      route_for(:controller => "messages", :action => "index").should == "/messages"
    end
  
    it "should map { :controller => 'messages', :action => 'new' } to /messages/new" do
      route_for(:controller => "messages", :action => "new").should == "/messages/new"
    end
  
    it "should map { :controller => 'messages', :action => 'edit', :id => 1 } to /messages/1/edit" do
      route_for(:controller => "messages", :action => "edit", :id => 1).should == "/messages/1/edit"
    end
  
    it "should map { :controller => 'messages', :action => 'update', :id => 1} to /messages/1" do
      route_for(:controller => "messages", :action => "update", :id => 1).should == "/messages/1"
    end
  
    it "should map { :controller => 'messages', :action => 'destroy', :id => 1} to /messages/1" do
      route_for(:controller => "messages", :action => "destroy", :id => 1).should == "/messages/1"
    end
  
    it "should map { :controller => 'messages', :action => 'mark_read', :id => 1} to /messages/1/mark_read" do
      route_for(:controller => "messages", :action => "mark_read", :id => 1).should == "/messages/1/mark_read"
    end
  
    it "should map { :controller => 'messages', :action => 'mark_read'} to /messages/mark_read" do
      route_for(:controller => "messages", :action => "mark_read").should == "/messages/mark_read"
    end
  end

  describe "route recognition" do

    it "should generate params { :controller => 'messages', action => 'index' } from GET /messages" do
      params_from(:get, "/messages").should == {:controller => "messages", :action => "index"}
    end
  
    it "should generate params { :controller => 'messages', action => 'new' } from GET /messages/new" do
      params_from(:get, "/messages/new").should == {:controller => "messages", :action => "new"}
    end
  
    it "should generate params { :controller => 'messages', action => 'create' } from POST /messages" do
      params_from(:post, "/messages").should == {:controller => "messages", :action => "create"}
    end
  
    it "should generate params { :controller => 'messages', action => 'edit', id => '1' } from GET /messages/1;edit" do
      params_from(:get, "/messages/1/edit").should == {:controller => "messages", :action => "edit", :id => "1"}
    end
  
    it "should generate params { :controller => 'messages', action => 'update', id => '1' } from PUT /messages/1" do
      params_from(:put, "/messages/1").should == {:controller => "messages", :action => "update", :id => "1"}
    end
  
    it "should generate params { :controller => 'messages', action => 'destroy', id => '1' } from DELETE /messages/1" do
      params_from(:delete, "/messages/1").should == {:controller => "messages", :action => "destroy", :id => "1"}
    end
  
    it "should generate params { :controller => 'messages', action => 'mark_read', id => '1' } from PUT /messages/1/mark_read" do
      params_from(:put, "/messages/1/mark_read").should == {:controller => "messages", :action => "mark_read", :id => "1"}
    end
  
    it "should generate params { :controller => 'messages', action => 'mark_read' } from PUT /messages/mark_read" do
      params_from(:put, "/messages/mark_read").should == {:controller => "messages", :action => "mark_read"}
    end
  end
end