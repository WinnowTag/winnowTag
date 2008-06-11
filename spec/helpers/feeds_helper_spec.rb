# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe FeedsHelper do
  include FeedsHelper

  describe "#feed_link" do
    before(:each) do
      @feed = mock_model(Feed, :via => "http://example.com/rss", :alternate => "http://example.com/blog", :title => "Feed Title")
    end
    
    it "contains a link to the feed's feed" do
      feed_link(@feed).should =~ /#{Regexp.escape(link_to("Feed", @feed.via, :class => "feed_icon replace"))}/
    end
    
    it "contains a link to the feeds homepage if it has an alternate url" do
      feed_link(@feed).should =~ /#{Regexp.escape(link_to("Feed Home", @feed.alternate, :class => "home_icon replace"))}/
    end
    
    it "contains a filler element when it does not have an alternate url" do
      @feed.stub!(:alternate)
      feed_link(@feed).should !~ /#{Regexp.escape(content_tag('span', '', :class => 'blank_icon replace'))}/
    end
    
    it "contains a link to the feeds page in winnow with the title as the link" do
      feed_link(@feed).should =~ /#{Regexp.escape(link_to("Feed Title", feed_path(@feed), :id => dom_id(@feed, "link_to")))}/
    end
  end
end