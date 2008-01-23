# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe Notifier do
  describe "deployment email" do
    before(:each) do
      @email = Notifier.create_deployed("mh", "the beast", "666", "mark", "go team")
    end

    it "is sent to wizzadmin" do
      @email.to.should == ["wizzadmin@peerworks.org"]
    end

    it "is sent from wizzadmin" do
      @email.from.should == ["wizzadmin@peerworks.org"]
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
      @invite = mock_model(Invite, :email => "user@example.com")
      @email = Notifier.create_invite_requested(@invite)
    end

    it "is sent to wizzadmin" do
      @email.to.should == ["wizzadmin@peerworks.org"]
    end

    it "is sent from wizzadmin" do
      @email.from.should == ["wizzadmin@peerworks.org"]
    end
    
    it "contains the invite email in the email body" do
      @email.body.should =~ /user@example.com/
    end
  end
end