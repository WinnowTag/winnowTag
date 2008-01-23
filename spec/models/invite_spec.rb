require File.dirname(__FILE__) + '/../spec_helper'

describe Invite do
  describe "validations" do
    it "validates the presence of email" do
      invite = Invite.new valid_invite_attributes(:email => nil)

      invite.should_not be_valid
      invite.should have(1).errors_on(:email)
    end
    
    it "validates uniqueness of email" do
      invite1 = Invite.create! valid_invite_attributes(:email => "some email")
      invite2 = Invite.new valid_invite_attributes(:email => "some email")
      
      invite2.should_not be_valid
      invite2.should have(1).errors_on(:email)
    end
  end
  
  describe "activation" do
    before(:each) do
      @invite = Invite.create! valid_invite_attributes
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
        Invite.create! valid_invite_attributes(:code => code)
        Invite.find_by_code(code).should_not be_nil
      
        Invite.find_active(code).should be_nil
      end
    end
    
    it "does not find invites which have been used" do
      Invite.create! valid_invite_attributes(:code => "some code", :user_id => 1)
        Invite.find_by_code("some code").should_not be_nil

      Invite.find_active("some code").should be_nil
    end
    
    it "find the invite with the given code" do
      Invite.create! valid_invite_attributes(:code => "some code")

      Invite.find_active("some code").should_not be_nil
    end
  end
end