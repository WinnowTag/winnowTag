# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class AccountController < ApplicationController
  # before_filter :setup_mailer_site_url
  skip_before_filter :login_required, :except => [:edit]
  
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
    if request.post?
      self.current_user = User.authenticate(params[:login], params[:password])
      if current_user
        current_user.login!
              
        if params[:remember_me] == "1"
          self.current_user.remember_me
          cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
        end
        redirect_back_or_default feed_items_path
      else
        flash[:warning] = "Invalid credentials. Please try again."
      end
    elsif params[:code]
      self.current_user = User.find(:first, :conditions => ["reminder_code = ? AND reminder_expires_at > ?", params[:code], Time.now])
      if current_user
        current_user.reminder_login!
        flash[:warning] = "Please update your password"
        redirect_to edit_account_path
      else
        flash[:error] = "Invalid reminder code"
        redirect_to login_path(:code => nil)
      end
    elsif params[:invite]
      @invite = Invite.find_active(params[:invite])
    end
  end

  def signup
    if @invite = Invite.find_active(params[:invite])
      @user = User.new(params[:user])
      if @user.save && @user.activate
        @invite.update_attribute :user_id, @user.id
        self.current_user = @user
        redirect_back_or_default using_path
      else
        render :action => 'login'
      end
    else
      redirect_to login_path
    end
  end
  
  def invite
    @invite = Invite.new(params[:invite])
    if @invite.save
      UserNotifier.deliver_invite_requested(@invite)
      Notifier.deliver_invite_requested(@invite)
      flash[:notice] = "Your invitation request has been submitted"
      redirect_to login_path
    else
      render :action => "login"
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
  
  def reminder
    if user = User.find_by_login(params[:login])
      user.enable_reminder!
      UserNotifier.deliver_reminder(user, login_url(user.reminder_code))
      render :update do |page|
        page[:notice].update "A password reminder has been sent"
        page[:notice].show
        page[:error].hide
      end
    else
      render :update do |page|
        page[:error].update "Invalid login"
        page[:error].show
        page[:notice].hide
      end
    end
  end 
  
# private
# 
#   def setup_mailer_site_url
#     UserNotifier.site_url = request.host_with_port    
#   end
end
