# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
require File.dirname(__FILE__) + '/../spec_helper'

# Need to explicitly require tag for the Tag() method
require 'tag'

describe FeedItemsHelper do
  attr_reader :current_user
  fixtures :feed_items

  before(:each) do
    @current_user = User.create! valid_user_attributes
  end
  
  describe "clean html" do
    it "strips scripts" do
      assert_equal("<h1>header</h1><p>content</p>", clean_html("<script>This is a script</script><h1>header</h1><p>content</p>"))
    end
  
    it "strips styles" do
      assert_equal("<h1>header</h1><p>content</p>", clean_html("<style>div {font-size:64px;}</style><h1>header</h1><p>content</p>"))
    end
  
    it "strips links" do
      assert_equal("<h1>header</h1><p>content</p>", clean_html('<link rel="foo"><h1>header</h1><p>content</p>'))
    end
  
    it "strips meta" do
      assert_equal("<h1>header</h1><p>content</p>", clean_html('<meta http-equiv="foo"><h1>header</h1><p>content</p>'))
    end
  
    it "clean_html_with_blank_value" do
      [nil, '', ' '].each do |value| 
        assert_nil clean_html(value)
      end
    end
  
    it "clean_html_with_non_blank_value" do
      ["string", "<div>content</div>"].each do |value| 
        assert_not_nil clean_html(value)
      end
    end
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
      tag = mock_model(Tag, :name => "tag1")
      classes = ["positive", "classifier"]
      tag_control_for(feed_item, tag, classes, nil).should have_tag("li.positive.classifier##{dom_id(feed_item, "tag_control_for_tag1_on")}") do
        with_tag "span.name", "tag1"
        with_tag "span.controls[style=?]", /display:none/ do
          with_tag "span.add"
          with_tag "span.remove"
        end
      end
    end
  end
  
  describe "tag controls" do
    it "created list items for each tag" do
      taggings = [
        [ mock_model(Tag, :name => "tag1"), [] ],
        [ mock_model(Tag, :name => "tag2"), [] ],
        [ mock_model(Tag, :name => "tag3"), [] ]
      ]
      feed_item = mock_model(FeedItem, :taggings_by_user => taggings)
    
      tag_controls(feed_item).should have_tag("ul.tag_list##{dom_id(feed_item, 'tag_controls')}") do
        with_tag("li", 3)
      end
    end
    
    xit "needs to be tested with public tags"
  end
  
  describe "tags_to_display" do
    it "only shows filtered tags when manual taggings is on" do
      params[:tag_ids] = "1,5,7"
      tags_to_display.should == [1, 5, 7]
    end
    
    it "only shows the tags the user has in the sidebar (public and private) that are not excluded plus any filtered tags" do
      ruby = mock_model(Tag)
      svn = mock_model(Tag)
      tech = mock_model(Tag)
      langs = mock_model(Tag)
      
      current_user.stub!(:sidebar_tags).and_return([ruby, svn])
      current_user.stub!(:subscribed_tags).and_return([tech, langs])
      current_user.stub!(:excluded_tags).and_return([ruby, langs])
      params[:tag_ids] = "1,5,7"
      
      tags_to_display.should == [svn.id, tech.id, 1, 5, 7]
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
