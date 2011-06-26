# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


# The +UserNotifier+ mailer is used to send emails to Winnow users.
class UserNotifier < ActionMailer::Base
  # This email is sent when a user makes a forgot password request.
  def reminder(user, url)
    setup_email user.email_address_with_name, :subject => I18n.t("winnow.email.reminder_subject")
    body        :user => user, :url => url
  end
  
  # This email is sent when a user submits an invitation request.
  def invite_requested(invite)
    setup_email invite.email, :subject => I18n.t("winnow.email.invite_requested_subject")
    body        :invite => invite
  end

  # This email is sent when a user's invitation request is accepted.
  def invite_accepted(invite, url)
    setup_email invite.email, :subject => invite.subject
    body        :url => url, :invite => invite
  end

protected
  def setup_email(email, options = {})
    recipients  email
    from        "dontreply@winnowtag.org"
    subject     "#{I18n.t('winnow.email.subject_prefix')} #{options[:subject]}"
  end
end
