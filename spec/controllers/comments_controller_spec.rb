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

describe CommentsController do
  describe "#create" do
    before(:each) do
      @comment = mock_model(Comment, :save => true, :read_by! => nil)
      
      @comments = stub("comments", :new => @comment)

      @current_user = Generate.user!
      login_as @current_user

      current_user.stub!(:comments).and_return(@comments)
    end
    
    def do_post
      post :create, :comment => {}
    end
    
    it "creates a new comment" do
      @comments.should_receive(:new).with({}).and_return(@comment)
      do_post
    end
    
    it "sets the comment for the view" do
      do_post
      assigns(:comment).should == @comment
    end
    
    describe "successful create" do
      it "marks the commment read by the current user" do
        @comment.should_receive(:read_by!).with(current_user)
        do_post
      end
      
      it "renders the create partial" do
        @comment.stub!(:save).and_return(true)
        do_post
        response.should render_template("create")
      end      
    end
    
    describe "unsuccessful create" do
      it "renders the error partial" do
        @comment.stub!(:save).and_return(false)
        do_post
        response.should render_template("error.js.rjs")
      end      
    end
  end
  
  describe "#edit" do
    before(:each) do
      @comment = mock_model(Comment)
      
      Comment.stub!(:find_for_user).and_return(@comment)

      @current_user = Generate.user!
      login_as @current_user
    end
    
    def do_get
      get :edit, :id => '1'
    end
    
    it "finds the comment" do
      Comment.should_receive(:find_for_user).with(@current_user, "1").and_return(@comment)
      do_get
    end
    
    it "sets the comment for the view" do
      do_get
      assigns(:comment).should == @comment
    end
    
    it "renders the edit partial" do
      do_get
      response.should render_template("edit")
    end
  end
  
  describe "#update" do
    before(:each) do
      @comment = mock_model(Comment, :update_attributes => true)
      
      Comment.stub!(:find_for_user).and_return(@comment)

      @current_user = Generate.user!
      login_as @current_user
    end
    
    def do_put
      put :update, :id => '1', :comment => {}
    end
    
    it "finds the comment" do
      Comment.should_receive(:find_for_user).with(@current_user, "1").and_return(@comment)
      do_put
    end
    
    it "updates the comment attribute" do
      @comment.should_receive(:update_attributes).with({})
      do_put
    end    
    
    it "sets the comment for the view" do
      do_put
      assigns(:comment).should == @comment
    end

    describe "successful update" do
      it "renders the update partial" do
        @comment.stub!(:update_attributes).and_return(true)
        do_put
        response.should render_template("update")
      end      
    end
    
    describe "unsuccessful update" do
      it "renders the error partial" do
        @comment.stub!(:update_attributes).and_return(false)
        do_put
        response.should render_template("error.js.rjs")
      end      
    end
  end
  
  describe "#destroy" do
    before(:each) do
      @comment = mock_model(Comment, :destroy => nil)
      
      Comment.stub!(:find_for_user).and_return(@comment)

      @current_user = Generate.user!
      login_as @current_user
    end
    
    def do_delete
      delete :destroy, :id => '1'
    end
    
    it "finds the comment" do
      Comment.should_receive(:find_for_user).with(@current_user, "1").and_return(@comment)
      do_delete
    end
    
    it "destroys the comment" do
      @comment.should_receive(:destroy)
      do_delete
    end    
    
    it "sets the comment for the view" do
      do_delete
      assigns(:comment).should == @comment
    end
    
    it "renders the destroy partial" do
      do_delete
      response.should render_template("destroy")
    end
  end
end
