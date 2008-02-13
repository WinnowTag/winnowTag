# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class UserNotifier < ActionMailer::Base
  def reminder(user, url)
    setup_email user.email, :subject => "Password Reminder"
    body        :user => user, :url => url
  end
  
  def invite_requested(invite)
    setup_email invite.email, :subject => "Invitation Requested"
    body        :invite => invite
  end
  
  def invite_accepted(invite, url)
    setup_email invite.email, :subject => invite.subject
    body        :url => url, :invite => invite
  end

  # include ActionController::UrlWriter
  # default_url_options[:host] = 'wizztag.org'
  # 
  # def self.site_url=(value)
  #   default_url_options[:host] = value
  # end
  #   
  # def signup_notification(user)
  #   setup_email user, :subject => "Welcome to Winnow, #{user.firstname}"
  #   body        :url => url_for(:controller => 'account', :action => 'activate', :activation_code => user.activation_code)
  # end
  # 
  # def activation(user)
  #   setup_email user, :subject => 'Your account has been activated!'
  #   body        :url => url_for(:controller => '')
  # end

protected
  def setup_email(email, options = {})
    recipients  email
    from        "wizzadmin@peerworks.org"
    subject     "[Winnow] #{options[:subject]}"
  end
end
