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

describe Notifier do
  describe "deployment email" do
    before(:each) do
      @email = Notifier.create_deployed("mh", "the beast", "666", "mark", "go team")
    end

    it "is sent to winnowtag_admin" do
      @email.to.should == ["winnowtag_admin@winnowtag.org"]
    end

    it "is sent from winnowtag_admin" do
      @email.from.should == ["winnowtag_admin@winnowtag.org"]
    end

    it "has a subect with revision info" do
      @email.subject.should =~ /r666/
    end
    
    it "contains the revision in the email body" do
      @email.body.should =~ /666/
    end
    
    it "contains the repository in the email body" do
      @email.body.should =~ /the beast/
    end
    
    it "contains the host in the email body" do
      @email.body.should =~ /mh/
    end
    
    it "contains the deployer in the email body" do
      @email.body.should =~ /mark/
    end
    
    it "contains the comment in the email body" do
      @email.body.should =~ /go team/
    end
  end

  describe "invite requested email" do
    before(:each) do
      @invite = mock_model(Invite, :email => "user@example.com", :hear => "found in google", :use => "feed reader")
      @email = Notifier.create_invite_requested(@invite)
    end

    it "is sent to winnowtag_admin" do
      @email.to.should == ["winnowtag_admin@winnowtag.org"]
    end

    it "is sent from dontreply" do
      @email.from.should == ["dontreply@winnowtag.org"]
    end
    
    it "contains the invite email in the email body" do
      @email.body.should =~ /user@example.com/
    end
  end
end