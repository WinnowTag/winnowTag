require File.dirname(__FILE__) + '/../spec_helper'

describe CommentsController do
  describe "#create" do
    before(:each) do
      referer("/tags/public")

      @comments = stub("comments", :create! => nil)

      @current_user = User.create! valid_user_attributes
      login_as @current_user

      current_user.stub!(:comments).and_return(@comments)
    end
    
    def do_post
      post :create, :comment => {}
    end
    
    it "creates a new comment" do
      @comments.should_receive(:create!).with({})
      do_post
    end
    
    it "redirects back to the last page" do
      referer("/tags/public")
      do_post
      response.should redirect_to("/tags/public")
    end
  end
end
