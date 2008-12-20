# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe UsersController do
  fixtures :users, :roles, :roles_users

  it "admin_required" do
    cannot_access(:quentin, :get, :index)
    cannot_access(:quentin, :get, :create)
    cannot_access(:quentin, :get, :login_as, :id => users(:quentin))
    cannot_access(:quentin, :get, :update, :id => users(:quentin))
    cannot_access(:quentin, :get, :destroy, :id => users(:quentin))
  end
  
  it "index" do
    login_as(:admin)
    get :index
    assert_response :success
  end
  
  it "new" do
    login_as(:admin)
    get :new
    assert_response :success
    # TODO: Move to view test
    # assert_select "form[action=#{users_path}]"
  end
  
  describe '#create' do
    def do_post
      post :create, :user => @user_params
    end
    
    before(:each) do
      login_as(:admin)
      
      @user_params = "user params"
      @user = mock_model(User)

      User.stub!(:create_from_prototype).and_return(@user)
    end
    
    it "should create a new user from the prototype" do
      User.should_receive(:create_from_prototype).with(@user_params).and_return(@user)
      do_post
    end
    
    describe "success" do
      it "redirect to the index action" do
        @user.stub!(:new_record?).and_return(false)
        do_post
        response.should redirect_to(users_path)
      end
    end
    
    describe "fail" do
      before(:each) do
        @user.stub!(:new_record?).and_return(true)
      end

      it "assigns the user for the view" do
        do_post
        assigns(:user).should == @user
      end
      
      it "render the new template" do
        do_post
        response.should render_template("new")
      end
    end
  end
  
  it "login_as_changes_current_user_and_redirects_to_index" do
    login_as(:admin)
    post :login_as, :id => users(:quentin).id
    assert_redirected_to('/')
    assert_equal users(:quentin).id, session[:user]
  end
    
  it "destroy" do
    login_as(:admin)
    delete :destroy, :id => users(:quentin).id
    assert_raise(ActiveRecord::RecordNotFound) {User.find(users(:quentin).id)}
    assert_redirected_to users_path
  end
end
