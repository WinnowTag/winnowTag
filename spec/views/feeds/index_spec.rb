# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../../spec_helper'

describe '/feeds/index' do
  before(:each) do
    login_as(1)
  end
  
  def render_it
    render '/feeds/index'
  end
  
  describe "non-empty result set" do
    before(:each) do
      @user = User.find(1)
      User.should_receive(:find_by_id).with(1).and_return(@user)
      @feeds = [mock_new_model(Feed, valid_feed_attributes)]
      @feeds.stub!(:page_count).and_return(1)
      assigns[:feeds] = @feeds
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
      @feeds = []
      @feeds.stub!(:page_count).and_return(0)
      assigns[:feeds] = @feeds
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