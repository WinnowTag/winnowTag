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