# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
require File.dirname(__FILE__) + '/../spec_helper'

# Need to explicitly require tag for the Tag() method
require 'tag'

describe FeedItemsHelper do
  include FeedItemsHelper

  attr_reader :current_user
  fixtures :feed_items

  before(:each) do
    @current_user = User.create! valid_user_attributes
  end
  
  describe "link_to_feed" do
    it "link_to_feed_without_link" do
      feed = mock_model(Feed, :title => "Feed Title", :alternate => nil)
      assert_equal "Feed Title", link_to_feed(feed)
    end
  
    it "link_to_feed_with_link" do
      feed = mock_model(Feed, :title => "Feed Title", :alternate => "http://example.com")
      assert_equal '<a href="http://example.com" target="_blank">Feed Title</a>', link_to_feed(feed)
    end
  end
  
  describe "link_to_feed_item" do
    it "link_to_feed_item_without_link" do
      feed_item = mock_model(FeedItem, :title => "FeedItem Title", :link => nil)
      assert_equal "FeedItem Title", link_to_feed_item(feed_item)
    end
  
    it "link_to_feed_item_with_link" do
      feed_item = mock_model(FeedItem, :title => "FeedItem Title", :link => "http://example.com")
      assert_equal '<a href="http://example.com" target="_blank">FeedItem Title</a>', link_to_feed_item(feed_item)
    end
  end
  
  describe "toggle_read_unread_button" do
    it "creates a link which triggers the itemBrowser's read/unread function" do
      toggle_read_unread_button.should have_tag("a[onclick=?]", /itemBrowser.toggleReadUnreadItem.*/)
    end
  end

  describe "classes_for_taggings" do
    it "provides the class classifier when only a classifier tagging exists" do
      taggings = mock_model(Tagging, :classifier_tagging? => true)
      classes_for_taggings(taggings).should == ["classifier"]
    end
    
    it "provides the class positive when a positive user tagging exists" do
      taggings = mock_model(Tagging, :classifier_tagging? => false, :positive? => true)
      classes_for_taggings(taggings).should == ["positive"]
    end

    it "provides the class negative when a negative user tagging exists" do
      taggings = mock_model(Tagging, :classifier_tagging? => false, :positive? => false, :negative? => true)
      classes_for_taggings(taggings).should == ["negative"]
    end
    
    it "provides the class classifier when a user tagging and a classifier tagging exist" do
      taggings = [ mock_model(Tagging, :classifier_tagging? => false, :positive? => true),
                   mock_model(Tagging, :classifier_tagging? => true) ]
      classes_for_taggings(taggings).should == ["positive", "classifier"]      
    end
    
    it "keeps classes given" do
      taggings = [ mock_model(Tagging, :classifier_tagging? => false, :positive? => true),
                   mock_model(Tagging, :classifier_tagging? => true) ]
      classes_for_taggings(taggings, ["public"]).should == ["public", "positive", "classifier"]      
    end
  end

  describe "tag control for" do
    it "creates a list item with the proper controls inside it" do
      feed_item = mock_model(FeedItem)
      
      tag = mock_model(Tag, :name => "tag1", :user => @current_user)
      classes = ["positive", "classifier"]
      tag_control_for(feed_item, tag, classes, nil).should have_tag("li.positive.classifier##{dom_id(feed_item, "tag_control_for_tag1_on")}") do
        with_tag ".name", "tag1"
        with_tag ".information" do
          with_tag "a.positive"
          with_tag "a.negative"
          with_tag "a.remove"
        end
      end
    end
  end
  
  describe "tag controls" do
    it "created list items for each tag" do
      taggings = [
        [ mock_model(Tag, :name => "tag1", :user => current_user), [] ],
        [ mock_model(Tag, :name => "tag2", :user => current_user), [] ],
        [ mock_model(Tag, :name => "tag3", :user => current_user), [] ]
      ]
      feed_item = mock_model(FeedItem, :taggings_to_display => taggings)
    
      tag_controls(feed_item).should have_tag("ul.tag_list##{dom_id(feed_item, 'tag_controls')}") do
        with_tag("li", 3)
      end
    end
  end
  
  describe "feed_item_title" do
    it "shows the feed items title if it has one" do
      feed_item = FeedItem.new :title => "Some Title"
      feed_item_title(feed_item).should == "Some Title"
    end
    
    it "shows (no title) if there is no title" do
      feed_item = FeedItem.new
      feed_item_title(feed_item).should have_tag(".notitle", "(no title)")
    end
  end
end
