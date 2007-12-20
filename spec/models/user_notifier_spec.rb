require File.dirname(__FILE__) + '/../spec_helper'

describe UserNotifier do
  describe "reminder email" do
    before(:each) do
      @user = mock_model(User, :email => "user@example.com")
      @url = "http://winnow.example.com/account/login/1232rrfwekl23x2d3dc2ec"
      @email = UserNotifier.create_reminder(@user, @url)
    end

    it "is sent to the requested user" do
      @email.to.should == [@user.email]
    end

    it "is described as a password reminder" do
      @email.subject.should =~ /Password Reminder/
    end
    
    it "contains the login url in the email body" do
      @email.body.should =~ /#{Regexp.escape(@url)}/
    end
  end
end