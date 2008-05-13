require File.dirname(__FILE__) + '/../spec_helper'

describe CommentsController do
  describe "#create" do
    before(:each) do
      @comment = mock_model(Comment)
      
      @comments = stub("comments", :create! => @comment)

      @current_user = User.create! valid_user_attributes
      login_as @current_user

      current_user.stub!(:comments).and_return(@comments)
    end
    
    def do_post
      post :create, :comment => {}
    end
    
    it "creates a new comment" do
      @comments.should_receive(:create!).with({}).and_return(@comment)
      do_post
    end
    
    it "sets the comment for the view" do
      do_post
      assigns(:comment).should == @comment
    end
    
    it "renders the create partial" do
      do_post
      response.should render_template("create")
    end
  end
  
  describe "#edit" do
    before(:each) do
      @comment = mock_model(Comment)
      
      Comment.stub!(:find_for_user).and_return(@comment)

      @current_user = User.create! valid_user_attributes
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
      @comment = mock_model(Comment, :update_attributes! => nil)
      
      Comment.stub!(:find_for_user).and_return(@comment)

      @current_user = User.create! valid_user_attributes
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
      @comment.should_receive(:update_attributes!).with({})
      do_put
    end    
    
    it "sets the comment for the view" do
      do_put
      assigns(:comment).should == @comment
    end
    
    it "renders the update partial" do
      do_put
      response.should render_template("update")
    end
  end
  
  describe "#destroy" do
    before(:each) do
      @comment = mock_model(Comment, :destroy => nil)
      
      Comment.stub!(:find_for_user).and_return(@comment)

      @current_user = User.create! valid_user_attributes
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
