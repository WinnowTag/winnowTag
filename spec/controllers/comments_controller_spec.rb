require File.dirname(__FILE__) + '/../spec_helper'

describe CommentsController do
  describe "#create" do
    before(:each) do
      referer("/tags/public")

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
end
