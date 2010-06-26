# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
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
