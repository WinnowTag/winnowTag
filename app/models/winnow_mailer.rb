# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
# winnow_mailer.rb
# Handles outgoing notification via email.

class WinnowMailer < ActionMailer::Base

  # TODO: Lines containing the string 'error' should be passed through
  # so that they appear in the body of the email.
  def winnow_run_log(log_url)
    sent_at = Time.now
    @subject    = 'Winnow collect completed ' + sent_at.to_s
    @body["message"]       = 'Winnow collect completed. Daily log file: ' + log_url
    @recipients = 'sawtelle@stonecutter.com'
    @from       = 'Winnow Admin <winnowadmin@peerworks.org>'
    @sent_on    = sent_at
    @headers    = {}
  end
end
