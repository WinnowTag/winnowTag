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
  
  describe "pinned_or_since" do
    it "doesn't return message created before the date" do
      since_date = 100.days.ago
      message1 = Message.create! :created_at => 110.days.ago, :body => "Some body"
      message2 = Message.create! :body => "Some other body"
      Message.pinned_or_since(since_date).should == [message2]
    end
    
    it "returns messages created on the date" do
      since_date = 100.days.ago
      message1 = Message.create! :created_at => since_date, :body => "Some body"
      message2 = Message.create! :body => "Some other body"
      Message.pinned_or_since(since_date).should == [message2, message1]
    end
    
    it "returns messages created before the date that are pinned" do
      since_date = 100.days.ago
      message1 = Message.create! :created_at => 110.days.ago, :pinned => true, :body => "Some body"
      message2 = Message.create! :body => "Some other body"
      Message.pinned_or_since(since_date).should == [message1, message2]
    end
    
    it "returns pinned messages first" do
      since_date = 100.days.ago
      message1 = Message.create! :pinned => false, :body => "some body"
      message2 = Message.create! :pinned => true, :body => "some body"
      Message.pinned_or_since(since_date).should == [message2, message1]
    end
    
    it "returns messages in reverse chronological order" do
      since_date = 100.days.ago
      message1 = Message.create! :pinned => false, :body => "some body", :created_at => 90.days.ago
      message2 = Message.create! :pinned => false, :body => "some body", :created_at => 60.days.ago
      message3 = Message.create! :pinned => true, :body => "some body", :created_at => 90.days.ago
      message4 = Message.create! :pinned => true, :body => "some body", :created_at => 60.days.ago
      Message.pinned_or_since(since_date).should == [message4, message3, message2, message1]      
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