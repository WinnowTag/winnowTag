require File.dirname(__FILE__) + '/../spec_helper'

describe Message do
  describe "validations" do
    before(:each) do
      @message = Message.new :body => "A Valid Body"
    end

    it "validates presence of body" do
      @message.should validate(:body, ["A Valid Body"], [nil, ""])
    end
  end

  describe "find_global" do
    it "returns only global messages" do
      message1 = Message.create! :body => "foo"
      message2 = Message.create! :body => "bar", :user_id => 1
      Message.find_global.should == [message1]
    end
  end
  
  describe "to_s" do
    it "returns the body" do
      message = Message.new :body => "A Valid Body"
      message.to_s.should == "A Valid Body"
    end
  end
end
