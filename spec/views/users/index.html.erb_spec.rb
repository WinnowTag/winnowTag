# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../../spec_helper'

describe '/users/index' do
  fixtures :users
  before(:each) do
    login_as(1)
  end
  
  def render_it
    render '/users/index'
  end
  
  describe "non-empty result set" do
    before(:each) do
      @users = [mock_model(User, :login => "login", :display_name => "display_name", :email => "email", :logged_in_at => Time.now, 
                                 :last_accessed_at => Time.now, :last_tagging_on => Time.now, :tags => [])]
      @users.stub!(:page_count).and_return(1)
      assigns[:users] = @users
    end
    
    it "should not show an empty message" do
      render_it
      response.should_not have_tag(".empty")
    end

    it "should show table" do
      render_it
      response.should have_tag("table")
    end
  end
  
  describe "empty result set" do
    before(:each) do
      @users = []
      @users.stub!(:page_count).and_return(0)
      assigns[:users] = @users
    end
    
    it "should show an empty message" do
      render_it
      response.should have_tag(".empty")
    end

    it "should not show table" do
      render_it
      response.should_not have_tag("table")
    end
  end
end