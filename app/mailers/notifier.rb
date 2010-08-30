# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

# The +Notifier+ mailer is used to send emails to the Winnow team.
class Notifier < ActionMailer::Base
  # This email is sent every time a deployment is made to either trunk or production.
  def deployed(host, repository, revision, deployer, comment)
    setup_email :subject => I18n.t("winnow.email.deployed_subject", :revision => revision), :from => "winnowtag_admin@winnowtag.org"
    body        :host => host, :repository => repository, :revision => revision, :deployer => deployer, :comment => comment
  end

  # This email is sent when a new invitation has been requested.
  def invite_requested(invite)
    setup_email :subject => "#{I18n.t('winnow.email.subject_prefix')} #{I18n.t('winnow.email.invite_requested_subject')}", :from => "dontreply@winnowtag.org"
    body        :invite => invite
  end
    
protected
  def setup_email(options = {})
    recipients  "winnowtag_admin@winnowtag.org"
    from        options[:from]
    subject     options[:subject]
  end
end