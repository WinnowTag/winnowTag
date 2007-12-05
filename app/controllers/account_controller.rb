# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class AccountController < ApplicationController
  # If you want "remember me" functionality, add this before_filter to Application Controller
  before_filter :setup_mailer_site_url
  skip_before_filter :login_required, :except => [:edit] # don't need to login for any of these actions
  skip_before_filter :load_view, :only => [ :logout ]
  
  def edit
    if request.post?
      params[:current_user].delete(:login)
      if current_user.update_attributes(params[:current_user])
        flash[:notice] = "Information updated"
        redirect_to :back
      end
    end
  end
  
  def login
    return unless request.post?
    self.current_user = User.authenticate(params[:login], params[:password])
    if current_user
      self.current_user.logged_in_at = Time.now 
      self.current_user.save
      
      if params[:remember_me] == "1"
        self.current_user.remember_me
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      end
      redirect_back_or_default feed_items_path
    else
      if user = User.find_by_login(params[:login]) and user.activated_at
        flash[:warning] = "Invalid credentials. Please try again."
      else
        flash[:notice] = "Your account has not been activated.  Please check your email for an activation link."
      end
    end
  end

  def signup
    @user = User.new(params[:user])
    if @user.save && @user.activate
      self.current_user = @user
      redirect_back_or_default feed_items_path
    else
      render :action => 'login'
    end
  end
  
  def logout
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    redirect_to(:action => 'login')
  end

  def activate
    if params[:activation_code]
      @user = User.find_by_activation_code(params[:activation_code]) 
    
      if @user and @user.activate
        self.current_user = @user
        redirect_back_or_default(root_path)
        flash[:notice] = "Your account has been activated." 
      else
        flash[:error] = "Unable to activate the account.  Did you provide the correct information?" 
      end
    else
      flash.clear
    end
  end
  
private

  def setup_mailer_site_url
    UserNotifier.site_url = request.host_with_port    
  end
end
