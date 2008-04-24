require File.dirname(__FILE__) + '/../spec_helper'

describe Feedback do
  describe "validations" do
    before(:each) do
      @feedback = Feedback.new
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
    it "can find feedback by body or by user login, email, firstname, or lastname" do
      user1 = User.create! valid_user_attributes(:login => "mark")
      feedback1 = user1.feedbacks.create! :body => "Just some request"
      user2 = User.create! valid_user_attributes(:email => "mark@example.com")
      feedback2 = user2.feedbacks.create! :body => "Just some request"
      user3 = User.create! valid_user_attributes(:firstname => "mark")
      feedback3 = user3.feedbacks.create! :body => "Just some request"
      user4 = User.create! valid_user_attributes(:lastname => "mark")
      feedback4 = user4.feedbacks.create! :body => "Just some request"
      user5 = User.create! valid_user_attributes
      feedback5 = user5.feedbacks.create! :body => "Some request from mark"
      user6 = User.create! valid_user_attributes
      feedback6 = user6.feedbacks.create! :body => "Just some request"
      
      feedbacks = Feedback.search :text_filter => "mark", :order => "id"
      feedbacks.should == [feedback1, feedback2, feedback3, feedback4, feedback5]
    end
  end
end
