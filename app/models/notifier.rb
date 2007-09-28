# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class Notifier < ActionMailer::Base

  def deployed(host, repository, revision, deployer, comment, sent_at = Time.now)
    @subject    = "[DEPLOYMENT] r#{revision} deployed"
    @recipients = 'wizzadmin@peerworks.org'
    @from       = 'wizzadmin@peerworks.org'
    @sent_on    = sent_at
    @headers    = {}
    @body       = {
      :host => host,
      :repository => repository,
      :revision => revision,
      :deployer => deployer,
      :comment => comment
    }
  end
end
