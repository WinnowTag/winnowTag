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
  fixtures :feed_items
  attr_reader :current_user, :session

  def setup
    @output = ""
    @current_user = User.create! valid_user_attributes
    @min_train_count = 1
    @session = {}
    @feed_item_count = nil
  end

  def test_clean_html_should_strip_scripts
    assert_equal("<h1>header</h1><p>content</p>", clean_html("<script>This is a script</script><h1>header</h1><p>content</p>"))
  end
  
  def test_clean_html_should_strip_styles
    assert_equal("<h1>header</h1><p>content</p>", clean_html("<style>div {font-size:64px;}</style><h1>header</h1><p>content</p>"))
  end
  
  def test_clean_html_should_strip_links
    assert_equal("<h1>header</h1><p>content</p>", clean_html('<link rel="foo"><h1>header</h1><p>content</p>'))
  end
  
  def test_clean_html_should_strip_meta
    assert_equal("<h1>header</h1><p>content</p>", clean_html('<meta http-equiv="foo"><h1>header</h1><p>content</p>'))
  end

  def test_tag_controls_helper_when_untagged
    @current_user.stub!(:tags).and_return([Tag(current_user, 'tag1'), Tag(current_user, 'tag2'), Tag(current_user, 'tag3')])
    fi = FeedItem.find(1)
    @response.body = tag_controls(fi)
    
    assert_select('li.untagged', 0, @response.body)
  end
  
  def test_tag_controls_with_classifier_tags
    Tagging.create(:feed_item => FeedItem.find(1), :user => @current_user, :tag => Tag(current_user, 'tag1'))
    Tagging.create(:feed_item => FeedItem.find(1), :user => @current_user, :tag => Tag(current_user, 'tag2'), :classifier_tagging => true)
    @response.body = tag_controls(FeedItem.find(1))
    
    assert_select('li#tag_control_for_tag1_on_feed_item_1.positive', true)
    assert_select('li#tag_control_for_tag2_on_feed_item_1.classifier', true)
  end
  
  def test_tag_controls_when_negative_tagging_exists
    Tagging.create(:feed_item => FeedItem.find(1), :user => @current_user, :tag => Tag(current_user, 'tag1'), :strength => 0)
    Tagging.create(:feed_item => FeedItem.find(1), :user => @current_user, :tag => Tag(current_user, 'tag1'), :classifier_tagging => true)
    
    params[:manual_taggings] = "true"
    response.body = tag_controls(FeedItem.find(1))
    
    assert_select('li#tag_control_for_tag1_on_feed_item_1.negative.classifier', true, @response.body)
  end
  
  def test_tag_controls_when_positive_tagging_overrides_classifier_tagging
    Tagging.create(:feed_item => FeedItem.find(1), :user => @current_user, :tag => Tag(current_user, 'tag1'))
    Tagging.create(:feed_item => FeedItem.find(1), :user => @current_user, :tag => Tag(current_user, 'tag1'), :classifier_tagging => true)
    @response.body = tag_controls(FeedItem.find(1))
    
    assert_select('li#tag_control_for_tag1_on_feed_item_1.positive.classifier', true, @response.body)
  end
    
  def test_display_tags_for_feed_item
    fi = FeedItem.find(1)
    Tagging.create(:user => current_user, :feed_item => fi, :tag => Tag(current_user, 'tag1'))
    Tagging.create(:user => current_user, :feed_item => fi, :tag => Tag(current_user, 'tag2'))
    Tagging.create(:user => current_user, :feed_item => fi, :tag => Tag(current_user, 'tag3'), :classifier_tagging => true)
    @response.body = display_tags_for(fi)
    
    assert_select("span.positive", "tag1", @response.body)
    assert_select("span.positive", "tag2")
    assert_select("span.classifier", "tag3")
  end
  
  def test_ununsed_tag_control_not_added_for_negative_tag
    @current_user.taggings.create(:tag => Tag(current_user, 'tag'), :feed_item => FeedItem.find(2))
    fi = FeedItem.find(1)
    Tagging.create(:user => @current_user, :feed_item => fi, :tag => Tag(current_user, 'tag'), :strength => 0)
    
    @response.body = unused_tag_controls(fi)
    assert_select('li#unused_tag_control_for_tag_on_feed_item_1', false, @response.body)
  end
      
  # TODO: Update this to work with published tags
  # def test_display_published_tags_when_tag_filter_is_a_published_tag
  #   tag_filter = TagPublication.find(1)
  #   fi = FeedItem.find(1)
  #   tag_filter.taggings.create(:tag => tag_filter.tag, :feed_item => fi)
  #   
  #   @view.add_tag :include, tag_filter
  #   @response.body = display_tags_for(fi)
  #   assert_select("span.tag_publication_tagging.tagged", "#{tag_filter.publisher.login}:#{tag_filter.tag.name}", "actual: " + @response.body)
  # end
  
  def test_clean_html_with_blank_value
    [nil, '', ' '].each do |value| 
      assert_nil clean_html(value)
    end
  end
  
  def test_clean_html_with_non_blank_value
    ["string", "<div>content</div>"].each do |value| 
      assert_not_nil clean_html(value)
    end
  end
  
  def test_feed_link_without_link
    feed_item = mock_model(FeedItem, :feed => mock_model(Feed, :title => "Feed Title", :alternate => nil))
    assert_equal "Feed Title", feed_link(feed_item)
  end
  
  def test_feed_link_with_link
    feed_item = mock_model(FeedItem, :feed => mock_model(Feed, :title => "Feed Title", :alternate => "http://example.com"))
    assert_equal '<a href="http://example.com">Feed Title</a>', feed_link(feed_item)
  end
  
  def test_feed_link_with_link_and_options
    feed_item = mock_model(FeedItem, :feed => mock_model(Feed, :title => "Feed Title", :alternate => "http://example.com"))
    assert_equal '<a href="http://example.com" target="_blank">Feed Title</a>', feed_link(feed_item, :target => "_blank")
  end
end
