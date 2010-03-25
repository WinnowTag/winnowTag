# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe FeedsHelper do
  include FeedsHelper

  describe "#feed_link" do
    before(:each) do
      @feed = mock_model(Feed, :via => "http://example.com/rss", :alternate => "http://example.com/blog", :title => "Feed Title")
    end
    
    it "contains a link to the feed's feed" do
      feed_link(@feed).should have_tag("a[href=?]", @feed.via)
    end
    
    it "contains a link to the feeds homepage if it has an alternate url" do
      feed_link(@feed).should have_tag("a[href=?]", @feed.alternate)
    end
    
    it "contains a filler element when it does not have an alternate url" do
      @feed.stub!(:alternate)
      feed_link(@feed).should !~ /#{Regexp.escape(content_tag('span', '', :class => 'blank'))}/
    end
    
    it "contains a link to filter by this feed" do
      feed_link(@feed).should have_tag("a[href=?]", feed_items_path(:anchor => "feed_ids=#{@feed.id}&feed_title=#{@feed.title}"), "Feed Title")
    end
  end
end