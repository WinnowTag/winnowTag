# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
require File.dirname(__FILE__) + '/../spec_helper'

describe Notifier do
  def setup
    ActiveRecord::Base.logger.info("NotifierTest")
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @expected = TMail::Mail.new
    @expected.set_content_type "text", "plain", { "charset" => "utf-8" }
    @expected.mime_version = '1.0'
  end

  def test_deployed
    @expected.subject = '[DEPLOYMENT] r666 deployed'
    @expected.from    = "wizzadmin@peerworks.org"
    @expected.to      = "wizzadmin@peerworks.org"
    @expected.body    = <<-EOMAIL
Hello Peerworks folk,

Revision 666 of "the beast" has just be deployed to  by .

Comment: 

Regards,

Winnow Deployment Notifier
EOMAIL
    @expected.date    = Time.now

    assert_equal @expected.encoded, Notifier.create_deployed("", "the beast", "666", "", "", @expected.date).encoded
  end
end