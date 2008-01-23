# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class Notifier < ActionMailer::Base
  def deployed(host, repository, revision, deployer, comment)
    setup_email :subject => "[DEPLOYMENT] r#{revision} deployed"
    body        :host => host, :repository => repository, :revision => revision, :deployer => deployer, :comment => comment
  end

  def invite_requested(invite)
    setup_email :subject => "[WINNOW] Invite Requested"
    body        :invite => invite
  end
    
protected
  def setup_email(options = {})
    recipients  "wizzadmin@peerworks.org"
    from        "wizzadmin@peerworks.org"
    subject     options[:subject]
  end
end