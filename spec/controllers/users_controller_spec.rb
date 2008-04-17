# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../spec_helper'

describe UsersController do
  fixtures :users, :roles, :roles_users

  def test_admin_required
    cannot_access(:quentin, :get, :index)
    cannot_access(:quentin, :get, :create)
    cannot_access(:quentin, :get, :show, :id => users(:quentin))
    cannot_access(:quentin, :get, :login_as, :id => users(:quentin))
    cannot_access(:quentin, :get, :update, :id => users(:quentin))
    cannot_access(:quentin, :get, :destroy, :id => users(:quentin))
  end
  
  def test_index
    login_as(:admin)
    get :index
    assert_response :success
  end
  
  def test_new
    login_as(:admin)
    get :new
    assert_response :success
    # TODO: Move to view test
    # assert_select "form[action=#{users_path}]"
  end
  
  def test_create
    login_as(:admin)
    assert_no_difference("User.count") do
      get :create
      assert_not_nil assigns(:user)
      assert_response :success
      assert_template 'create'
    end
  end
  
  def test_create
    assert_difference("User.count", 1) do
      login_as(:admin)
      post :create, :user => { :login => 'quire', :email => 'quire@example.com', 
                               :firstname => 'Qu', :lastname => 'Ire',
                               :password => 'quire', :password_confirmation => 'quire' }
      assert_response :redirect
      assert_redirected_to :action => 'index'
      assert user = User.find_by_login('quire')
      assert_not_nil user.activated_at
    end
  end
  
  def test_show
    login_as(:admin)
    get :show, :id => users(:quentin).id
    assert_response :success
    assert_not_nil assigns(:user)
    assert_equal users(:quentin), assigns(:user)
  end
  
  def test_show_works_with_login
    login_as(:admin)
    get :show, :id => users(:quentin).login
    assert_response :success
    assert_not_nil assigns(:user)
    assert_equal users(:quentin), assigns(:user)
  end
    
  def test_login_as_changes_current_user_and_redirects_to_index
    login_as(:admin)
    post :login_as, :id => users(:quentin).id
    assert_redirected_to('/')
    assert_equal users(:quentin).id, session[:user]
  end
    
  def test_destroy
    login_as(:admin)
    delete :destroy, :id => users(:quentin).id
    assert_raise(ActiveRecord::RecordNotFound) {User.find(users(:quentin).id)}
    assert_redirected_to users_path
  end
end
