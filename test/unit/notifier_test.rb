require File.dirname(__FILE__) + '/../test_helper'

class NotifierTest < Test::Unit::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "utf-8"

  include ActionMailer::Quoting

  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @expected = TMail::Mail.new
    @expected.set_content_type "text", "plain", { "charset" => CHARSET }
    @expected.mime_version = '1.0'
  end

  def test_deployed
    @expected.subject = '[DEPLOYMENT] r666 deployed'
    @expected.from    = "wizzadmin@peerworks.org"
    @expected.to      = "wizzadmin@peerworks.org"
    @expected.body    = read_fixture('deployed')
    @expected.date    = Time.now

    assert_equal @expected.encoded, Notifier.create_deployed("", "the beast", "666", "", "", @expected.date).encoded
  end

  private
    def read_fixture(action)
      IO.readlines("#{FIXTURES_PATH}/notifier/#{action}")
    end

    def encode(subject)
      quoted_printable(subject, CHARSET)
    end
end
