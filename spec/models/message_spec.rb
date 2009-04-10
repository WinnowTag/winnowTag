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
  
  describe "global" do
    it "returns only global messages" do
      message1 = Message.create! :body => "foo"
      message2 = Message.create! :body => "bar", :user_id => 1
      Message.global.should == [message1]
    end
  end
  
  describe "since" do
    it "doesn't return message created before the date" do
      since_date = 100.days.ago
      message1 = Message.create! :created_at => 110.days.ago, :body => "Some body"
      message2 = Message.create! :body => "Some other body"
      Message.since(since_date).should == [message2]
    end
    
    it "returns messages created on the date" do
      since_date = 100.days.ago
      message1 = Message.create! :created_at => since_date, :body => "Some body"
      message2 = Message.create! :body => "Some other body"
      Message.since(since_date).should == [message1, message2]
    end
  end
  
  describe "info_cutoff" do
    it "returns a time" do
      Message.info_cutoff.should be_a(Time) 
    end
  end

  describe "for" do
    it "returns only global messages and messages belonging to the specified user" do
      user1, user2 = mock_model(User), mock_model(User)
      message1 = Message.create! :body => "foo"
      message2 = Message.create! :body => "bar", :user_id => user1.id
      message3 = Message.create! :body => "baz", :user_id => user2.id
      Message.for(user1).should == [message1, message2]
    end
  end
  
  describe "unread for" do
    it "returns only global messages and messages belonging to the specified user" do
      user1, user2 = mock_model(User), mock_model(User)
      
      message1 = Message.create! :body => "foo1"
      message2 = Message.create! :body => "foo2"
      message3 = Message.create! :body => "bar1", :user_id => user1.id
      message4 = Message.create! :body => "bar2", :user_id => user1.id
      message5 = Message.create! :body => "baz", :user_id => user2.id
      
      Reading.create! :readable_type => "Message", :readable_id => message1.id, :user_id => user1.id
      Reading.create! :readable_type => "Message", :readable_id => message3.id, :user_id => user1.id
      
      Message.unread(user1).for(user1).should == [message2, message4]
    end  
  end
end