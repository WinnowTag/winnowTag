require File.dirname(__FILE__) + '/../spec_helper'

describe User do
  describe "logging login" do 
    before(:each) do
      @user = User.create! valid_user_attributes
      @time = Time.now
      
      @user.logged_in_at.should_not == @time
      @user.login!(@time)
    end

    it "updates the last login time" do
      @user.logged_in_at.should == @time
    end

    # it "saves the last login time" do
    #   @user.reload
    #   @user.logged_in_at.should == @time
    # end
  end
  
  describe "logging reminder login" do 
    before(:each) do
      @user = User.create! valid_user_attributes(:reminder_code => "some randome string", :reminder_expires_at => 2.days.from_now)
      @time = Time.now
      
      @user.logged_in_at.should_not == @time
      @user.reminder_code.should_not be_nil
      @user.reminder_expires_at.should_not be_nil
      @user.reminder_login!(@time)
    end

    it "updates the last login time" do
      @user.logged_in_at.should == @time
    end

    # it "saves the last login time" do
    #   @user.reload
    #   @user.logged_in_at.should == @time
    # end

    it "clears the reminder coder" do
      @user.reminder_code.should be_nil
    end

    it "clear the reminder expiration time" do
      @user.reminder_expires_at.should be_nil
    end
  end
  
  describe "enabling reminder login" do 
    before(:each) do
      @user = User.create! valid_user_attributes

      @user.reminder_code.should be_nil
      @user.reminder_expires_at.should be_nil
      @user.enable_reminder!
    end

    it "sets the reminder coder" do
      @user.reminder_code.should_not be_nil
    end

    it "sets the reminder expiration time" do
      @user.reminder_expires_at.should_not be_nil
    end
  end
end