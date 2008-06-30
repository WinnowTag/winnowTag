# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class AccountController < ApplicationController
  # before_filter :setup_mailer_site_url
  skip_before_filter :login_required, :except => [:edit]
  
  def edit
    if request.post?
      params[:current_user].delete(:login)
      if current_user.update_attributes(params[:current_user])
        flash[:notice] = _(:profile_update)
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
        flash[:warning] = _(:credentials_invalid)
      end
    elsif params[:code]
      self.current_user = User.find(:first, :conditions => ["reminder_code = ? AND reminder_expires_at > ?", params[:code], Time.now])
      if current_user
        current_user.reminder_login!
        flash[:warning] = _(:update_password)
        redirect_to edit_account_path
      else
        flash[:error] = _(:reminder_invalid)
        redirect_to login_path(:code => nil)
      end
    elsif params[:invite]
      @invite = Invite.find_active(params[:invite])
    end
  end

  def signup
    if @invite = Invite.find_active(params[:invite])
      @user = User.create_from_prototype(params[:user])
      unless @user.new_record?
        @invite.update_attribute :user_id, @user.id
        self.current_user = @user
        redirect_back_or_default info_path
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
      flash[:notice] = _(:invitation_submitted)
      redirect_to login_path
    else
      render :action => "login"
    end
  end
  
  def logout
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    redirect_to login_path
  end

  def activate
    if params[:activation_code]
      @user = User.find_by_activation_code(params[:activation_code]) 
    
      if @user and @user.activate
        self.current_user = @user
        redirect_back_or_default(root_path)
        flash[:notice] = _(:account_activated)
      else
        flash[:error] = _(:account_activation_failed)
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
        page[:notice].update _(:reminder_sent)
        page[:notice].show
        page[:error].hide
      end
    else
      render :update do |page|
        page[:error].update _(:login_invalid)
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
