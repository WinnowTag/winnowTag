# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe AccountController do
  describe "reminder" do
    it "should deliver the reminder email with a token login url" do
      user = mock_model(User, :login => "mark", :reminder_code => "123", :enable_reminder! => nil)
      User.stub!(:find_by_login).with(user.login).and_return(user)

      UserNotifier.should_receive(:deliver_reminder).with(user, login_url(user.reminder_code))
      
      post :reminder, :login => user.login
    end
  end

  describe "others" do
    it "should_login_and_redirect_to_feed_items_path" do
      user = Generate.user!
      post :login, :login => user.login, :password => "password"
      assert session[:user]
      response.should redirect_to(feed_items_path)
    end

    it "should_fail_login_and_not_redirect" do
      user = Generate.user!
      post :login, :login => user.login, :password => "bad password"
      assert_nil session[:user]
      assert_response :success
    end

    it "should_allow_signup_and_redirect_to_feed_items_path" do
      assert_difference "User.count" do
        create_user
        assert session[:user]
        response.should redirect_to(feed_items_path)
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
      login_as Generate.user!
      get :logout
      assert_nil session[:user]
      assert_response :redirect
    end

    it "should_remember_me" do
      user = Generate.user!
      post :login, :login => user.login, :password => "password", :remember_me => "1"
      assert_not_nil @response.cookies["auth_token"]
    end

    it "should_not_remember_me" do
      user = Generate.user!
      post :login, :login => user.login, :password => "password", :remember_me => "0"
      assert_nil @response.cookies["auth_token"]
    end
  
    it "should_delete_token_on_logout" do
      login_as Generate.user!
      get :logout
      response.cookies["auth_token"].should be_nil
    end

    it "should_login_with_cookie" do
      user = Generate.user!
      user.remember_me
      @request.cookies["auth_token"] = cookie_for(user)
      get :edit
      assert @controller.send(:logged_in?)
    end

    it "should_fail_cookie_login" do
      user = Generate.user!
      user.remember_me
      user.update_attribute :remember_token_expires_at, 5.minutes.ago.utc
      @request.cookies["auth_token"] = cookie_for(user)
      get :edit
      assert !@controller.send(:logged_in?)
    end

    it "should_fail_cookie_login_again" do
      user = Generate.user!
      user.remember_me
      @request.cookies["auth_token"] = auth_token('invalid_auth_token')
      get :edit
      assert !@controller.send(:logged_in?)
    end
  
    it "edit_can_only_change_some_values" do
      user = Generate.user!
      original_login = user.login
      original_crypted_password = user.crypted_password

      login_as user

      referer "/feed_items"
      post :edit, :current_user => {:firstname => 'Someone', :lastname => 'Else', :email => 'someone@else.com'}

      user.reload
      user.firstname.should == "Someone"
      user.lastname.should == "Else"
      user.email.should == "someone@else.com"

      user.login.should == original_login
      user.crypted_password.to_s.should == user.crypted_password.to_s

      assert_redirected_to "/feed_items"
    end
  
    it "get_edit_returns_the_form" do
      login_as Generate.user!
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
      user = Generate.user!
      previous_login_time = user.logged_in_at
      post :login, :login => user.login, :password => "password"
    
      user.reload
      assert_not_nil user.logged_in_at
      assert_not_equal previous_login_time, user.logged_in_at
    end
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
    auth_token user.remember_token
  end
end
