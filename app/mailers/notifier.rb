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

  # This email is sent when the number of signups reaches the daily limit
  def signups_requested_today(subject, signups_today, daily_signup_limit)
    setup_email :subject => "#{I18n.t('winnow.email.subject_prefix')} #{subject}", :from => "dontreply@winnowtag.org"
    body        :signups_today => signups_today, :daily_signup_limit => daily_signup_limit
  end
    
protected
  def setup_email(options = {})
    recipients  "winnowtag_admin@winnowtag.org"
    from        options[:from]
    subject     options[:subject]
  end
end