require File.dirname(__FILE__) + '/../spec_helper'

describe AccountController do
  fixtures :users

  before(:each) do
    @emails = ActionMailer::Base.deliveries 
    @emails.clear
  end

  it "should_login_and_redirect_to_feed_items_path" do
    post :login, :login => 'quentin', :password => 'test'
    assert session[:user]
    response.should redirect_to(feed_items_path)
  end

  it "should_fail_login_and_not_redirect" do
    post :login, :login => 'quentin', :password => 'bad password'
    assert_nil session[:user]
    assert_response :success
  end

  it "should_allow_signup_and_redirect_to_info_path" do
    assert_difference "User.count" do
      create_user
      assert session[:user]
      response.should redirect_to(info_path)
    end
  end

  it "should_require_login_on_signup" do
    assert_no_difference "User.count" do
      create_user(:login => nil)
      assert assigns(:user).errors.on(:login)
      assert_response :success
    end
  end

  it "should_require_password_on_signup" do
    assert_no_difference "User.count" do
      create_user(:password => nil)
      assert assigns(:user).errors.on(:password)
      assert_response :success
    end
  end

  it "should_require_email_on_signup" do
    assert_no_difference "User.count" do
      create_user(:email => nil)
      assert assigns(:user).errors.on(:email)
      assert_response :success
    end
  end

  it "should_logout" do
    login_as :quentin
    get :logout
    assert_nil session[:user]
    assert_response :redirect
  end

  it "should_remember_me" do
    post :login, :login => 'quentin', :password => 'test', :remember_me => "1"
    assert_not_nil @response.cookies["auth_token"]
  end

  it "should_not_remember_me" do
    post :login, :login => 'quentin', :password => 'test', :remember_me => "0"
    assert_nil @response.cookies["auth_token"]
  end
  
  it "should_delete_token_on_logout" do
    login_as :quentin
    get :logout
    assert_equal @response.cookies["auth_token"], []
  end

  it "should_login_with_cookie" do
    users(:quentin).remember_me
    @request.cookies["auth_token"] = cookie_for(:quentin)
    get :edit
    assert @controller.send(:logged_in?)
  end

  it "should_fail_cookie_login" do
    users(:quentin).remember_me
    users(:quentin).update_attribute :remember_token_expires_at, 5.minutes.ago.utc
    @request.cookies["auth_token"] = cookie_for(:quentin)
    get :edit
    assert !@controller.send(:logged_in?)
  end

  it "should_fail_cookie_login_again" do
    users(:quentin).remember_me
    @request.cookies["auth_token"] = auth_token('invalid_auth_token')
    get :edit
    assert !@controller.send(:logged_in?)
  end
  
  it "should_activate_user" do
    assert_nil User.authenticate('aaron', 'test')
    get :activate, :activation_code => users(:aaron).activation_code
    assert_equal users(:aaron), User.authenticate('aaron', 'test')
  end
  
  it "should_not_activate_nil" do
    get :activate, :activation_code => nil
    assert_activate_error
  end

  it "should_not_activate_bad" do
    get :activate, :activation_code => 'foobar'
    assert flash.has_key?(:error), "Flash should contain error message." 
    assert_activate_error
  end

  it "edit_can_only_change_some_values" do
    referer('')
    login_as(:quentin)
    post :edit, :current_user => {:firstname => 'Someone', :lastname => 'Else', :email => 'someone@else.com', :login => 'evil'}
    u = User.find(users(:quentin).id)
    assert_equal 'Someone', u.firstname
    assert_equal 'Else', u.lastname
    assert_equal 'someone@else.com', u.email
    assert_equal users(:quentin).crypted_password, u.crypted_password
    assert_equal users(:quentin).login, u.login
    assert_redirected_to ''
  end
  
  it "get_edit_returns_the_form" do
    login_as(:quentin)
    get :edit
    assert_response :success
    assert_template 'edit'
  end
  
  it "edit_requires_login" do
    assert_requires_login do 
      get :edit
      post :edit
    end
  end
      
  it "login_updates_logged_in_at_time" do
    previous_login_time = User.find_by_login('quentin').logged_in_at
    post :login, :login => 'quentin', :password => 'test'
    assert_not_nil User.find_by_login('quentin').logged_in_at
    assert_not_equal previous_login_time, User.find_by_login('quentin').logged_in_at
  end
    
protected
  def create_user(options = {})
    attributes = { :login => 'quire', :email => 'quire@example.com', :firstname => 'Qu', :lastname => 'Ire', 
                   :password => 'quire', :password_confirmation => 'quire' }.merge(options)
    invite = Invite.create!(:email => 'user@example.com')
    invite.activate!
    post :signup, :invite => invite.code, :user => attributes
  end

  def auth_token(token)
    CGI::Cookie.new('name' => 'auth_token', 'value' => token)
  end

  def cookie_for(user)
    auth_token users(user).remember_token
  end

  def assert_activate_error
    assert_response :success
    assert_template "account/activate" 
  end
end
