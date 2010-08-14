# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

# The +AccountController+ is resposible for all account related actions,
# such as invitation requests, signups, activations, logins, logouts, 
# password reminders, and profile/password editing.
# 
# Except for the profile/password editing actions, this controller is 
# publically accessible and does not require any user to be logged in.
class AccountController < ApplicationController
  skip_before_filter :login_required, :except => [:edit, :edit_password]
  skip_before_filter :check_if_user_must_update_password, :only => [:edit_password, :logout]
  
  # The +edit+ action is used to edit the logged in users profile.
  def edit
    if request.post?
      if current_user.update_attributes(params[:current_user])
        flash[:notice] = t("winnow.notifications.profile_updated")
        redirect_to feed_items_path
      end
    end
  end
  
  # The +edit_password+ action is used to edit the logged in users password.
  def edit_password
    if request.post?
      if current_user.update_attributes(params[:current_user].merge(:crypted_password => nil))
        session[:user_must_update_password] = false
        flash[:notice] = t("winnow.notifications.password_changed")
        redirect_to feed_items_path
      end
    end
  end
  
  # The +get_signup_link+ action is used to edit the logged in users password.
  # def get_signup_link
  #   if request.post?
  #     if current_user.update_attributes(params[:current_user].merge(:crypted_password => nil))
  #       session[:user_must_update_password] = false
  #       flash[:notice] = t("winnow.notifications.profile_updated")
  #       redirect_to :back
  #     end
  #   end
  # end

  # The +login+ action handles logging in from a number of routes.
  # 1. POST request containing a login/password. This method will 
  #    also set a remember me cookie if request by the user.
  # 2. GET request with a code in the url. This method is to support
  #    the links users receive when they request a password reminder.
  # 
  # This actions is also the landing place for users who received an 
  # invitation, in which case the signup form is displayed instead 
  # of the login form.
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
        flash.now[:warning] = t("winnow.notifications.credentials_invalid")
      end
    elsif params[:code]
      self.current_user = User.find(:first, :conditions => ["reminder_code = ? AND reminder_expires_at > ?", params[:code], Time.now])
      if current_user
        session[:user_must_update_password] = true
        current_user.reminder_login!
        flash[:warning] = t("winnow.notifications.update_password")
        redirect_to edit_password_path
      else
        flash[:error] = t("winnow.notifications.reminder_code_invalid")
      end
    elsif params[:invite]
      @invite = Invite.active(params[:invite])
      if @invite.blank? || @invite.code.blank?
        flash[:error] = t("winnow.notifications.invitation_code_invalid")
      end
    end
  end

  # The +signup+ action is used to compelte a user's signup request.
  # A signup requires a valid invitation. Once the signup is completed,
  # the new user is logged in and directed to the info page.
  def signup
    if @invite = Invite.active(params[:invite])
      @user = User.create_from_prototype(params[:user])
      unless @user.new_record?
        @invite.update_attribute :user_id, @user.id
        self.current_user = @user
        redirect_back_or_default feed_items_path
      else
        render :action => 'login'
      end
    else
      redirect_to feed_items_path
    end
  end
  
  # The +invite+ action is to request an invitation to Winnow.
  def invite
    @invite = Invite.new(params[:invite])
    if verify_recaptcha(:model => @invite, :message => t("winnow.general.recaptcha_failed")) and @invite.save
      # UserNotifier.deliver_invite_requested(@invite)
      Notifier.deliver_invite_requested(@invite)
      flash[:notice] = t("winnow.notifications.sign_up_link_sent")
      @invite.activate!
      UserNotifier.deliver_invite_accepted(@invite, login_url(:invite => @invite.code))
      redirect_to sent_signup_link_path
    else
      render :action => 'get_signup_link'
    end
  end
  
  # The +logout+ action logs the current user out, deleteds their
  # remember be cookie, and resets all their session data.
  def logout
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    redirect_to root_path
  end

  # The +reminder+ action is used to request a password reminder
  # when a user cannot remember their password. This will email the
  # user a link they can click, which will log them in and allow
  # them to set their password.
  def reminder
    if user = User.find_by_login(params[:login])
      user.enable_reminder!
      UserNotifier.deliver_reminder(user, login_url(user.reminder_code))
      render :update do |page|
        page << "Message.add('notice', #{t('winnow.notifications.reminder_sent').to_json});"
      end
    else
      render :update do |page|
        page << "Message.add('error', #{t('winnow.notifications.credentials_invalid').to_json});"
      end
    end
  end
end
