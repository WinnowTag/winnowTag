# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

require File.dirname(__FILE__) + '/../spec_helper'

describe UserNotifier, "#reminder" do
    
  before(:each) do
    @user = mock_model(User, :email_address_with_name => '"John Doe" <jdoe@example.com>')
    @url = "http://example.com/"
    @email = UserNotifier.create_reminder(@user, @url)
  end
  
  it "addresses the email from the admin address" do
    @email.from.should == ["winnowadmin@mindloom.org"]
  end
  
  it "addresses the email to the user" do
    to = @email.to_addrs.first
    to.name.should == "John Doe"
    to.address.should == "jdoe@example.com"
  end
  
  it "sets the subject" do
    @email.subject.should == "[WINNOW] Password Reminder"
  end
  
  it "includes the url in the body" do
    @email.body.should match(/#{Regexp.escape(@url)}/)
  end
  
end

describe UserNotifier, "#invite_requested" do
    
  before(:each) do
    @invite = mock_model(Invite, :email => "jdoe@example.com")
    @email = UserNotifier.create_invite_requested(@invite)
  end
  
  it "addresses the email from the admin address" do
    @email.from.should == ["winnowadmin@mindloom.org"]
  end
  
  it "addresses the email to the invite email address" do
    @email.to.should == [@invite.email]
  end
  
  it "sets the subject" do
    @email.subject.should == "[WINNOW] Invite Requested"
  end
  
  it "includes the email in the body" do
    @email.body.should match(/#{@invite.email}/)
  end
  
end

describe UserNotifier, "#invite_accepted" do
    
  before(:each) do
    @invite = mock_model(Invite, :email => "jdoe@example.com", :subject => "Invitation Accepted", :body => "body")
    @url = "http://example.com/"
    @email = UserNotifier.create_invite_accepted(@invite, @url)
  end
  
  it "addresses the email from the admin address" do
    @email.from.should == ["winnowadmin@mindloom.org"]
  end
  
  it "addresses the email to the invite email address" do
    @email.to.should == ["jdoe@example.com"]
  end
  
  it "sets the subject" do
    @email.subject.should == "[WINNOW] Invitation Accepted"
  end
  
  it "includes the invite body in the body" do
    @email.body.should match(/#{Regexp.escape(@invite.body)}/)
  end
  
  it "includes the url in the body" do
    @email.body.should match(/#{Regexp.escape(@url)}/)
  end
  
end
