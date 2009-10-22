# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe Feedback do
  describe "validations" do
    before(:each) do
      @feedback = Feedback.new :user_id => 1, :body => "some feedback"
    end

    it "should be valid" do
      @feedback.should be_valid
    end
  end

  describe "associations" do
    before(:each) do
      @feedback = Feedback.new
    end

    it "should be belong to a user" do
      @feedback.should belong_to(:user)
    end
  end
  
  describe "search" do
    it "can find feedback by body or by user login" do
      user1 = Generate.user!(:login => "mark")
      feedback1 = user1.feedbacks.create! :body => "Just some request"
      user5 = Generate.user!
      feedback5 = user5.feedbacks.create! :body => "Some request from mark"
      user6 = Generate.user!
      feedback6 = user6.feedbacks.create! :body => "Just some request"
      
      feedbacks = Feedback.search :text_filter => "mark", :order => "id"
      feedbacks.should == [feedback1, feedback5]
    end
  end
end
