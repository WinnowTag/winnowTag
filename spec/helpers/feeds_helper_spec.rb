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