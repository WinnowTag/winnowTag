# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe MessageReading do
  before(:each) do
    @message_reading = MessageReading.new
  end

  it "should be valid" do
    @message_reading.should be_valid
  end
end
