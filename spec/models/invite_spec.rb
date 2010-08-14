# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe Invite do
  describe "validations" do
    it "validates the presence of email" do
      invite = Generate.invite(:email => nil)

      invite.should_not be_valid
      invite.should have(2).errors_on(:email)
    end
  end
  
  describe "activation" do
    before(:each) do
      @invite = Generate.invite!
      @invite.code.should be_nil
    end

    it "sets a unique code" do
      @invite.activate!
      @invite.code.should_not be_nil
    end

    it "saves the invite" do
      @invite.activate!
      @invite.reload
      @invite.code.should_not be_nil
    end
  end
  
  describe "finding active invitations" do
    it "does not find invites with blank code" do
      [nil, ""].each do |code|
        Generate.invite!(:code => code)
        Invite.find_by_code(code).should_not be_nil
      
        Invite.active(code).should be_nil
      end
    end
    
    it "does not find invites which have been used" do
      Generate.invite!(:code => "some code", :user_id => 1)
      Invite.find_by_code("some code").should_not be_nil

      Invite.active("some code").should be_nil
    end
    
    it "find the invite with the given code" do
      Generate.invite!(:code => "some code")

      Invite.active("some code").should_not be_nil
    end
  end

  describe "searching" do
    it "can find invites by email" do
      invite1 = Generate.invite!(:email => "mark@example.com")
      invite2 = Generate.invite!
      
      expected_invites = [invite1]
      
      invites = Invite.search :text_filter => "mark", :order => "id"
      invites.should == expected_invites
    end
  end
end