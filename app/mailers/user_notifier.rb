# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class UserNotifier < ActionMailer::Base
  def reminder(user, url)
    setup_email user.email, :subject => I18n.t("winnow.email.reminder_subject")
    body        :user => user, :url => url
  end
  
  def invite_requested(invite)
    setup_email invite.email, :subject => I18n.t("winnow.email.invite_requested_subject")
    body        :invite => invite
  end
  
  def invite_accepted(invite, url)
    setup_email invite.email, :subject => invite.subject
    body        :url => url, :invite => invite
  end

protected
  def setup_email(email, options = {})
    recipients  email
    from        "winnowadmin@mindloom.org"
    subject     "#{I18n.t('winnow.email.subject_prefix')} #{options[:subject]}"
  end
end
