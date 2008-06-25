# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
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
  
  describe "invite requested email" do
    before(:each) do
      @invite = mock_model(Invite, :email => "user@example.com")
      @email = UserNotifier.create_invite_requested(@invite)
    end

    it "is sent to the requested invitation email" do
      @email.to.should == [@invite.email]
    end

    it "is described as a invite request" do
      @email.subject.should =~ /Invite Requested/
    end
  end
  
  describe "invite accepted email" do
    before(:each) do
      @invite = mock_model(Invite, :email => "user@example.com", :code => "somecode", :subject => "Invitation Accepted", :body => "Thanks for joining!")
      @url = "http://winnow.example.com/account/login?invite=somecode"
      @email = UserNotifier.create_invite_accepted(@invite, @url)
    end

    it "is sent to the requested invitation email" do
      @email.to.should == [@invite.email]
    end

    it "is described as a invite accepted" do
      @email.subject.should =~ /Invitation Accepted/
    end
    
    it "contains the signup url in the email body" do
      @email.body.should =~ /#{Regexp.escape(@url)}/
    end
    
    it "contains the custom body in the email body" do
      @email.body.should =~ /Thanks for joining!/
    end
  end
end