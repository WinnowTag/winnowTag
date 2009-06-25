# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe UsersController do
  it "admin_required" do
    user = Generate.user!
    
    cannot_access(user, :get, :index)
    cannot_access(user, :get, :new)
    cannot_access(user, :post, :create)
    cannot_access(user, :delete, :destroy,  :id => user)
    cannot_access(user, :post, :login_as, :id => user)
  end
  
  it "index" do
    login_as Generate.admin!
    get :index
    assert_response :success
  end
  
  it "new" do
    login_as Generate.admin!
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
      login_as Generate.admin!
      
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
    user = Generate.user!
    
    login_as Generate.admin!
    post :login_as, :id => user.id
    assert_redirected_to('/')
    assert_equal user.id, session[:user]
  end
    
  it "destroy" do
    user = Generate.user!
    
    login_as Generate.admin!
    delete :destroy, :id => user.id
    assert_raise(ActiveRecord::RecordNotFound) { user.reload }
    assert_redirected_to users_path
  end
end
