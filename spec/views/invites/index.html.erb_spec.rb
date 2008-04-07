# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../../spec_helper'

describe '/invites/index' do
  before(:each) do
    login_as(1)
  end
  
  def render_it
    render '/invites/index'
  end
  
  describe "non-empty result set" do
    before(:each) do
      @invites = [mock_model(Invite, :email => "email", :hear => "hear", :use => "use", :created_at => Time.now, :subject => "subject", 
                                     :body => "body", :code? => false, :user => mock_model(User, :login => "login"))]
      @invites.stub!(:page_count).and_return(1)
      assigns[:invites] = @invites
    end
    
    it "should not show an empty message" do
      render_it
      response.should_not have_tag(".empty")
    end

    it "should show a list of invites" do
      render_it
      response.should have_tag(".invite")
    end
  end
  
  describe "empty result set" do
    before(:each) do
      @invites = []
      @invites.stub!(:page_count).and_return(0)
      assigns[:invites] = @invites
    end
    
    it "should show an empty message" do
      render_it
      response.should have_tag(".empty")
    end

    it "should not show a list of invites" do
      render_it
      response.should_not have_tag(".invite")
    end
  end
end