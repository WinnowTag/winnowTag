# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe CommentsController do
  describe "#create" do
    before(:each) do
      @comment = mock_model(Comment, :save => true)
      
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
  
  describe "#mark_read" do
    def mark_comments_read
      xhr :put, :mark_read, :comment_ids => @comments.map(&:to_param)
    end
    
    before(:each) do
      @comments = [mock_model(Comment, :read_by! => nil), mock_model(Comment, :read_by! => nil)]
      
      Comment.stub!(:find).and_return(@comments)
      
      @current_user = User.create! valid_user_attributes
      login_as @current_user
    end
    
    it "finds the comments" do
      Comment.should_receive(:find).with(@comments.map(&:to_param)).and_return(@comments)
      mark_comments_read
    end
    
    it "marks the comments as read" do
      @comments.each do |comment|
        comment.should_receive(:read_by!).with(@current_user)
      end
      mark_comments_read
    end
    
    it "renders the mark_read partial" do
      mark_comments_read
      response.should render_template("mark_read")
    end
  end
end
