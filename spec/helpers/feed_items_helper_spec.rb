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

describe FeedItemsHelper do
  before(:each) do
    def helper.current_user
      @current_user ||= Generate.user!
    end
  end
  
  describe "classes_for_taggings" do
    it "provides the class classifier when only a classifier tagging exists" do
      taggings = mock_model(Tagging, :positive? => true, :classifier_tagging? => true, :negative? => false)
      helper.classes_for_taggings(taggings).should == ["classifier"]
    end
    
    it "provides the class positive when a positive user tagging exists" do
      taggings = mock_model(Tagging, :classifier_tagging? => false, :positive? => true, :negative? => false)
      helper.classes_for_taggings(taggings).should == ["positive"]
    end

    it "provides the class negative when a negative user tagging exists" do
      taggings = mock_model(Tagging, :classifier_tagging? => false, :positive? => false, :negative? => true)
      helper.classes_for_taggings(taggings).should == ["negative"]
    end
    
    it "provides the class classifier when a user tagging and a classifier tagging exist" do
      taggings = [ mock_model(Tagging, :classifier_tagging? => false, :positive? => true, :negative? => false),
                   mock_model(Tagging, :classifier_tagging? => true, :positive? => true, :negative? => false) ]
      helper.classes_for_taggings(taggings).should == ["positive", "classifier"]      
    end
    
    it "keeps classes given" do
      taggings = [ mock_model(Tagging, :classifier_tagging? => false, :positive? => true, :negative? => false),
                   mock_model(Tagging, :classifier_tagging? => true, :positive? => true, :negative? => false) ]
      helper.classes_for_taggings(taggings, ["public"]).should == ["public", "positive", "classifier"]      
    end
  end

  describe "feed_item_title" do
    it "shows the feed items title if it has one" do
      feed_item = FeedItem.new :title => "Some Title"
      helper.feed_item_title(feed_item).should == "Some Title"
    end
    
    it "shows (no title) if there is no title" do
      feed_item = FeedItem.new
      helper.feed_item_title(feed_item).should have_tag(".notitle", "(no title)")
    end
  end
end
