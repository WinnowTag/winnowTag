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

describe MessagesController do
  describe "route generation" do
    it "should map { :controller => 'messages', :action => 'index' } to /messages" do
      route_for(:controller => "messages", :action => "index").should == "/messages"
    end
  
    it "should map { :controller => 'messages', :action => 'new' } to /messages/new" do
      route_for(:controller => "messages", :action => "new").should == "/messages/new"
    end
  
    it "should map { :controller => 'messages', :action => 'edit', :id => '1' } to /messages/1/edit" do
      route_for(:controller => "messages", :action => "edit", :id => "1").should == "/messages/1/edit"
    end
  
    it "should map { :controller => 'messages', :action => 'update', :id => '1' } to /messages/1" do
      route_for(:controller => "messages", :action => "update", :id => "1").should == { :path => "/messages/1", :method => :put }
    end
  
    it "should map { :controller => 'messages', :action => 'destroy', :id => '1' } to /messages/1" do
      route_for(:controller => "messages", :action => "destroy", :id => "1").should == { :path => "/messages/1", :method => :delete }
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
  end
end