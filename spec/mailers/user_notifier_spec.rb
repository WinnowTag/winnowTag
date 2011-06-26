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

describe UserNotifier, "#reminder" do
    
  before(:each) do
    @user = mock_model(User, :email_address_with_name => '"John Doe" <jdoe@example.com>')
    @url = "http://example.com/"
    @email = UserNotifier.create_reminder(@user, @url)
  end
  
  it "addresses the email from the dontreply address" do
    @email.from.should == ["dontreply@winnowtag.org"]
  end
  
  it "addresses the email to the user" do
    to = @email.to_addrs.first
    to.name.should == "John Doe"
    to.address.should == "jdoe@example.com"
  end
  
  it "sets the subject" do
    @email.subject.should == "[winnowTag] Password Reset"
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
  
  it "addresses the email from the dontreply address" do
    @email.from.should == ["dontreply@winnowtag.org"]
  end
  
  it "addresses the email to the invite email address" do
    @email.to.should == [@invite.email]
  end
  
  it "sets the subject" do
    @email.subject.should == "[winnowTag] 'Sign up' link requested"
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
  
  it "addresses the email from the dontreply address" do
    @email.from.should == ["dontreply@winnowtag.org"]
  end
  
  it "addresses the email to the invite email address" do
    @email.to.should == ["jdoe@example.com"]
  end
  
  it "sets the subject" do
    @email.subject.should == "[winnowTag] Invitation Accepted"
  end
  
  it "includes the invite body in the body" do
    @email.body.should match(/#{Regexp.escape(@invite.body)}/)
  end
  
  it "includes the url in the body" do
    @email.body.should match(/#{Regexp.escape(@url)}/)
  end
  
end
