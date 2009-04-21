# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class Notifier < ActionMailer::Base
  def deployed(host, repository, revision, deployer, comment)
    setup_email :subject => I18n.t("winnow.email.deployed_subject", :revision => revision)
    body        :host => host, :repository => repository, :revision => revision, :deployer => deployer, :comment => comment
  end

  def invite_requested(invite)
    setup_email :subject => "#{I18n.t('winnow.email.subject_prefix')} #{I18n.t('winnow.email.invite_requested_subject')}"
    body        :invite => invite
  end
    
protected
  def setup_email(options = {})
    recipients  "winnowadmin@mindloom.org"
    from        "winnowadmin@mindloom.org"
    subject     options[:subject]
  end
end