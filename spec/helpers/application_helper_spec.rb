# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe ApplicationHelper do
  attr_reader :current_user
  
  before(:each) do
    @current_user = mock_model(User, valid_user_attributes)
  end
  
  describe "#globally_exclude_check_box" do
    before(:each) do
      @current_user.stub!(:globally_excluded?).and_return(:false)
    end
    
    it "should handle Remote::Feeds" do
      feed = mock_model(Remote::Feed, valid_feed_attributes)
      globally_exclude_check_box(feed).should =~ /\/feeds\/#{feed.id}/
    end
  end
  
  describe "#help_path" do
    def controller_name; @controller_name; end
    def action_name; @action_name; end

    it "points to the same controller on docs.mindloom.org" do
      @controller_name = "feeds"
      help_path.should == "http://docs.mindloom.org/feeds"
    end

    it "points to the same controller/action on docs.mindloom.org" do
      @controller_name = "tags"
      @action_name = "public"
      help_path.should == "http://docs.mindloom.org/tags/public"
    end
  end
end