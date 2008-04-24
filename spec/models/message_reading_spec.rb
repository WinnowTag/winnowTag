require File.dirname(__FILE__) + '/../spec_helper'

describe MessageReading do
  before(:each) do
    @message_reading = MessageReading.new
  end

  it "should be valid" do
    @message_reading.should be_valid
  end
end
