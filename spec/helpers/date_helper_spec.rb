# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe DateHelper do
  include DateHelper

  before(:each) do
    Time.zone = "Eastern Time (US & Canada)"
  end

  it "formats as date when more than 1 day ago" do
    time = 3.days.ago
    format_date(time).should == time.strftime("%e %b, %y")
  end
  
  it "formts as time when less than 1 day ago" do
    time = Time.zone.now
    format_date(time).should == time.strftime("%H:%M %p")
  end
  
  it "nil_date_returns_never" do
    format_date(nil).should == "Never"
  end
end