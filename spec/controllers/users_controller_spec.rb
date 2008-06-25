# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe UsersController do
  fixtures :users, :roles, :roles_users

  it "admin_required" do
    cannot_access(:quentin, :get, :index)
    cannot_access(:quentin, :get, :create)
    cannot_access(:quentin, :get, :show, :id => users(:quentin))
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
  
  it "create" do
    login_as(:admin)
    assert_no_difference("User.count") do
      post :create
      assert_not_nil assigns(:user)
      assert_response :success
      assert_template 'new'
    end
  end
  
  it "create" do
    assert_difference("User.count", 1) do
      login_as(:admin)
      post :create, :user => { :login => 'quire', :email => 'quire@example.com', 
                               :firstname => 'Qu', :lastname => 'Ire',
                               :password => 'quire', :password_confirmation => 'quire' }
      assert_redirected_to users_path
      assert user = User.find_by_login('quire')
      assert_not_nil user.activated_at
    end
  end
  
  it "show" do
    login_as(:admin)
    get :show, :id => users(:quentin).id
    assert_response :success
    assert_not_nil assigns(:user)
    assert_equal users(:quentin), assigns(:user)
  end
  
  it "show_works_with_login" do
    login_as(:admin)
    get :show, :id => users(:quentin).login
    assert_response :success
    assert_not_nil assigns(:user)
    assert_equal users(:quentin), assigns(:user)
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
