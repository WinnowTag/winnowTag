# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
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
  
  describe "to_s" do
    it "returns the body" do
      message = Message.new :body => "A Valid Body"
      message.to_s.should == "A Valid Body"
    end
  end
  
  describe "find_global" do
    it "returns only global messages" do
      message1 = Message.create! :body => "foo"
      message2 = Message.create! :body => "bar", :user_id => 1
      Message.find_global.should == [message1]
    end
  end

  describe "find_for_user_and_global" do
    it "returns only global messages and messages belonging to the specified user" do
      message1 = Message.create! :body => "foo"
      message2 = Message.create! :body => "bar", :user_id => 1
      message3 = Message.create! :body => "baz", :user_id => 2
      Message.find_for_user_and_global(1).should == [message1, message2]
    end
  end
  
  describe "find_unread_for_user_and_global" do
    it "returns only global messages and messages belonging to the specified user" do
      message1 = Message.create! :body => "foo1"
      message2 = Message.create! :body => "foo2"
      message3 = Message.create! :body => "bar1", :user_id => 1
      message4 = Message.create! :body => "bar2", :user_id => 1
      message5 = Message.create! :body => "baz", :user_id => 2
      
      Reading.create! :readable_type => "Message", :readable_id => message1.id, :user_id => 1
      Reading.create! :readable_type => "Message", :readable_id => message3.id, :user_id => 1
      
      Message.find_unread_for_user_and_global(1).should == [message2, message4]
    end  
  end
end