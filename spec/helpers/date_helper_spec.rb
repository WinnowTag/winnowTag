# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
require File.dirname(__FILE__) + '/../spec_helper'

describe DateHelper do
  attr_accessor :current_user

  it "format_date_uses_users_time_zone" do
    self.current_user = User.new
    self.current_user.time_zone = "Australia/Adelaide"
    time = Time.now.ago(3.days)
    assert_match(current_user.tz.utc_to_local(time).strftime("%e %b, %y"), format_date(time))
  end
  
  it "format_todays_date_uses_users_time_zone" do
    self.current_user = User.new
    self.current_user.time_zone = "Australia/Adelaide"
    time = Time.now.utc
    assert_match(current_user.tz.utc_to_local(time).strftime("%H:%M %p"), format_date(time))
  end
  
  it "nil_date_returns_never" do
    assert_equal("Never", format_date(nil))
  end
end