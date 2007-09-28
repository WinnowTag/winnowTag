require File.dirname(__FILE__) + '/../test_helper'
require 'account_controller'

# Re-raise errors caught by the controller.
class AccountController; def rescue_action(e) raise e end; end

class AccountControllerTest < Test::Unit::TestCase

  fixtures :users

  def setup
    @controller = AccountController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    AccountController.signup_disabled = false
    # for testing action mailer
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    @emails = ActionMailer::Base.deliveries 
    @emails.clear
  end

  def test_should_login_and_redirect
    post :login, :login => 'quentin', :password => 'test'
    assert session[:user]
    assert_response :redirect
  end

  def test_should_fail_login_and_not_redirect
    post :login, :login => 'quentin', :password => 'bad password'
    assert_nil session[:user]
    assert_response :success
  end

  def test_should_allow_signup
    assert_difference User, :count do
      create_user
      assert_response :redirect
      assert_nil session[:user]
    end
  end

  def test_should_require_login_on_signup
    assert_no_difference User, :count do
      create_user(:login => nil)
      assert assigns(:user).errors.on(:login)
      assert_response :success
    end
  end

  def test_should_require_password_on_signup
    assert_no_difference User, :count do
      create_user(:password => nil)
      assert assigns(:user).errors.on(:password)
      assert_response :success
    end
  end

  def test_should_require_password_confirmation_on_signup
    assert_no_difference User, :count do
      create_user(:password_confirmation => nil)
      assert assigns(:user).errors.on(:password_confirmation)
      assert_response :success
    end
  end

  def test_should_require_email_on_signup
    assert_no_difference User, :count do
      create_user(:email => nil)
      assert assigns(:user).errors.on(:email)
      assert_response :success
    end
  end

  def test_should_logout
    login_as :quentin
    get :logout
    assert_nil session[:user]
    assert_response :redirect
  end

  def test_should_remember_me
    post :login, :login => 'quentin', :password => 'test', :remember_me => "1"
    assert_not_nil @response.cookies["auth_token"]
  end

  def test_should_not_remember_me
    post :login, :login => 'quentin', :password => 'test', :remember_me => "0"
    assert_nil @response.cookies["auth_token"]
  end
  
  def test_should_delete_token_on_logout
    login_as :quentin
    get :logout
    assert_equal @response.cookies["auth_token"], []
  end

  def test_should_login_with_cookie
    users(:quentin).remember_me
    @request.cookies["auth_token"] = cookie_for(:quentin)
    get :index
    assert @controller.send(:logged_in?)
  end

  def test_should_fail_cookie_login
    users(:quentin).remember_me
    users(:quentin).update_attribute :remember_token_expires_at, 5.minutes.ago.utc
    @request.cookies["auth_token"] = cookie_for(:quentin)
    get :index
    assert !@controller.send(:logged_in?)
  end

  def test_should_fail_cookie_login
    users(:quentin).remember_me
    @request.cookies["auth_token"] = auth_token('invalid_auth_token')
    get :index
    assert !@controller.send(:logged_in?)
  end
  
  def test_should_activate_user
    assert_nil User.authenticate('aaron', 'test')
    get :activate, :activation_code => users(:aaron).activation_code
    assert_equal users(:aaron), User.authenticate('aaron', 'test')
  end
  
  def test_should_not_activate_nil
    get :activate, :activation_code => nil
    assert_activate_error
  end

  def test_should_not_activate_bad
    get :activate, :activation_code => 'foobar'
    assert flash.has_key?(:error), "Flash should contain error message." 
    assert_activate_error
  end

  def assert_activate_error
    assert_response :success
    assert_template "account/activate" 
  end

  def _test_should_activate_user_and_send_activation_email
    get :activate, :activation_code => users(:aaron).activation_code
    assert_equal 1, @emails.length
    assert(@emails.first.subject =~ /Your account has been activated/)
    assert(@emails.first.body    =~ /#{assigns(:user).firstname}, your account has been activated/)
  end

  def _test_should_send_activation_email_after_signup
    create_user
    assert_equal 1, @emails.length
    assert(@emails.first.subject =~ /Welcome to Winnow, #{assigns(:user).firstname}/)
    assert(@emails.first.body    =~ /account\/activate\?activation_code=#{assigns(:user).activation_code}/)
  end
  
  def test_edit_can_only_change_some_values
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
  
  def test_edit_shows_timezone_select_set_to_current_timezone
    login_as(:quentin)
    get :edit, :view_id => users(:quentin).views.create
    assert_select "select[name='current_user[time_zone]']", true do
      assert_select "option[value='#{users(:quentin).time_zone}']", true
    end
  end
  
  def test_get_edit_returns_the_form
    login_as(:quentin)
    get :edit, :view_id => users(:quentin).views.create
    assert_response :success
    assert_template 'edit'
  end
  
  def test_edit_requires_login
    assert_requires_login do 
      get :edit
      post :edit
    end
  end
  
  def test_should_allow_password_change
    referer("")
    post :login, :login => 'quentin', :password => 'test'
    post :change_password, { :old_password => 'test', :password => 'newpassword', :password_confirmation => 'newpassword' }
    assert_equal 'newpassword', assigns(:current_user).password
    assert_equal "Password changed", flash[:notice]
    assert_redirected_to ''
    post :logout
    assert_nil session[:user]
    post :login, :login => 'quentin', :password => 'newpassword'
    assert session[:user] 
    assert_response :redirect
  end

  def test_non_matching_passwords_should_not_change
    post :login, :login => 'quentin', :password => 'test'
    assert session[:user]
    post :change_password, { :old_password => 'test', :password => 'newpassword', :password_confirmation => 'test' }
    assert_not_equal 'newpassword', assigns(:current_user).password
    assert_equal "Password mismatch", flash[:notice]
  end

  def test_incorrect_old_password_does_not_change
    post :login, :login => 'quentin', :password => 'test'
    assert session[:user]
    post :change_password, { :old_password => 'wrongpassword', :password => 'newpassword', :password_confirmation => 'newpassword' }
    assert_not_equal 'newpassword', assigns(:current_user).password
    assert_equal "Wrong password", flash[:notice]
  end
    
  def test_login_updates_logged_in_at_time
    previous_login_time = User.find_by_login('quentin').logged_in_at
    post :login, :login => 'quentin', :password => 'test'
    assert_not_nil User.find_by_login('quentin').logged_in_at
    assert_not_equal previous_login_time, User.find_by_login('quentin').logged_in_at
  end
  
  def test_disable_signup
    AccountController.signup_disabled = true
    referer('')
    get :signup
    assert_redirected_to ''
  end
  
  protected
    def create_user(options = {})
      post :signup, :user => { :login => 'quire', :email => 'quire@example.com', :firstname => 'Qu', :lastname => 'Ire',
        :password => 'quire', :password_confirmation => 'quire' }.merge(options)
    end
    
    def auth_token(token)
      CGI::Cookie.new('name' => 'auth_token', 'value' => token)
    end
    
    def cookie_for(user)
      auth_token users(user).remember_token
    end
end
