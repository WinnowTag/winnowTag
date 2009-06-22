# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe FeedItemsHelper do
  before(:each) do
    def helper.current_user
      @current_user ||= Generate.user!
    end
  end
  
  describe "link_to_feed" do
    it "link_to_feed_without_link" do
      feed = mock_model(Feed, :title => "Feed Title", :alternate => nil)
      assert_equal "Feed Title", helper.link_to_feed(feed)
    end
  
    it "link_to_feed_with_link" do
      feed = mock_model(Feed, :title => "Feed Title", :alternate => "http://example.com")
      assert_equal '<a href="http://example.com" target="_blank">Feed Title</a>', helper.link_to_feed(feed)
    end
  end
  
  describe "link_to_feed_item" do
    it "link_to_feed_item_without_link" do
      feed_item = mock_model(FeedItem, :title => "FeedItem Title", :link => nil)
      assert_equal "FeedItem Title", helper.link_to_feed_item(feed_item)
    end
  
    it "link_to_feed_item_with_link" do
      feed_item = mock_model(FeedItem, :title => "FeedItem Title", :link => "http://example.com")
      assert_equal '<a href="http://example.com" target="_blank">FeedItem Title</a>', helper.link_to_feed_item(feed_item)
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

  describe "tag control for" do
    it "creates a list item with the proper controls inside it" do
      feed_item = mock_model(FeedItem)
      
      tag = mock_model(Tag, :name => "tag1", :user => helper.current_user, :user_id => helper.current_user.id)
      classes = ["positive", "classifier"]
      helper.tag_control_for(feed_item, tag, classes, nil).should have_tag("li.positive.classifier") do
        with_tag ".name", "tag1"
      end
    end
  end
  
  describe "tag controls" do
    it "created list items for each tag" do
      taggings = [
        [ mock_model(Tag, :name => "tag1", :user => helper.current_user, :user_id => helper.current_user.id), [] ],
        [ mock_model(Tag, :name => "tag2", :user => helper.current_user, :user_id => helper.current_user.id), [] ],
        [ mock_model(Tag, :name => "tag3", :user => helper.current_user, :user_id => helper.current_user.id), [] ]
      ]
      feed_item = mock_model(FeedItem, :taggings_to_display => taggings)
    
      helper.tag_controls(feed_item).should have_tag("ul.tag_list") do
        with_tag("li", 3)
      end
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
