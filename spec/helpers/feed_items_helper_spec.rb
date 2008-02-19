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

  it "clean_html_should_strip_scripts" do
    assert_equal("<h1>header</h1><p>content</p>", clean_html("<script>This is a script</script><h1>header</h1><p>content</p>"))
  end
  
  it "clean_html_should_strip_styles" do
    assert_equal("<h1>header</h1><p>content</p>", clean_html("<style>div {font-size:64px;}</style><h1>header</h1><p>content</p>"))
  end
  
  it "clean_html_should_strip_links" do
    assert_equal("<h1>header</h1><p>content</p>", clean_html('<link rel="foo"><h1>header</h1><p>content</p>'))
  end
  
  it "clean_html_should_strip_meta" do
    assert_equal("<h1>header</h1><p>content</p>", clean_html('<meta http-equiv="foo"><h1>header</h1><p>content</p>'))
  end

  it "tag_controls_helper_when_untagged" do
    @current_user.stub!(:tags).and_return([Tag(current_user, 'tag1'), Tag(current_user, 'tag2'), Tag(current_user, 'tag3')])
    fi = FeedItem.find(1)
    @response.body = tag_controls(fi)
    
    assert_select('li.untagged', 0, @response.body)
  end
  
  it "tag_controls_with_classifier_tags" do
    Tagging.create(:feed_item => FeedItem.find(1), :user => @current_user, :tag => Tag(current_user, 'tag1'))
    Tagging.create(:feed_item => FeedItem.find(1), :user => @current_user, :tag => Tag(current_user, 'tag2'), :classifier_tagging => true)
    @response.body = tag_controls(FeedItem.find(1))
    
    assert_select('li#tag_control_for_tag1_on_feed_item_1.positive', true)
    assert_select('li#tag_control_for_tag2_on_feed_item_1.classifier', true)
  end
  
  it "tag_controls_when_negative_tagging_exists" do
    Tagging.create(:feed_item => FeedItem.find(1), :user => @current_user, :tag => Tag(current_user, 'tag1'), :strength => 0)
    Tagging.create(:feed_item => FeedItem.find(1), :user => @current_user, :tag => Tag(current_user, 'tag1'), :classifier_tagging => true)
    
    params[:manual_taggings] = "true"
    response.body = tag_controls(FeedItem.find(1))
    
    assert_select('li#tag_control_for_tag1_on_feed_item_1.negative.classifier', true, @response.body)
  end
  
  it "tag_controls_when_positive_tagging_overrides_classifier_tagging" do
    Tagging.create(:feed_item => FeedItem.find(1), :user => @current_user, :tag => Tag(current_user, 'tag1'))
    Tagging.create(:feed_item => FeedItem.find(1), :user => @current_user, :tag => Tag(current_user, 'tag1'), :classifier_tagging => true)
    @response.body = tag_controls(FeedItem.find(1))
    
    assert_select('li#tag_control_for_tag1_on_feed_item_1.positive.classifier', true, @response.body)
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
  
  it "feed_link_without_link" do
    feed_item = mock_model(FeedItem, :feed => mock_model(Feed, :title => "Feed Title", :alternate => nil))
    assert_equal "Feed Title", feed_link(feed_item)
  end
  
  it "feed_link_with_link" do
    feed_item = mock_model(FeedItem, :feed => mock_model(Feed, :title => "Feed Title", :alternate => "http://example.com"))
    assert_equal '<a href="http://example.com">Feed Title</a>', feed_link(feed_item)
  end
  
  it "feed_link_with_link_and_options" do
    feed_item = mock_model(FeedItem, :feed => mock_model(Feed, :title => "Feed Title", :alternate => "http://example.com"))
    assert_equal '<a href="http://example.com" target="_blank">Feed Title</a>', feed_link(feed_item, :target => "_blank")
  end
end
