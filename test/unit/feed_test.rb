# Copyright (c) 2006 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
require File.dirname(__FILE__) + '/../test_helper'

class FeedTest < Test::Unit::TestCase
  fixtures :feeds, :feed_items, :users, :tags
  
  def test_find_with_item_counts_without_tag_and_tagger_returns_all_feeds
    feeds = Feed.find_with_item_counts
    assert_equal 2, feeds.size
    assert_equal 'Ruby Documentation', feeds[0].title
    assert_equal 1, feeds[0].item_count.to_i
    assert_equal 'Ruby Language', feeds[1].title
    assert_equal 3, feeds[1].item_count.to_i
  end
    
  def test_find_with_item_counts_with_tag_and_tagger_uses_tagged_items_as_counts
    tag = Tag.find_or_create_by_name('peerworks')
    tagging = Tagging.create(:tag => tag, :tagger => users(:quentin), :taggable => FeedItem.find(1))
    feeds = Feed.find_with_item_counts(:user => users(:quentin), :tag_filter => { :include => [tag] })
    assert_equal 1, feeds.size
    assert_equal 'Ruby Language', feeds[0].title
    assert_equal 1, feeds[0].item_count.to_i
  end
    
  def test_find_with_item_counts_ignores_other_users_tags
    # make sure other users tags aren't detected
    tag = Tag.find_or_create_by_name('peerworks')
    tagging = Tagging.create(:tag => tag, :tagger => users(:quentin), :taggable => FeedItem.find(1))
    Tagging.create(:tag => tag, :tagger => users(:aaron), :taggable => FeedItem.find(4))
    feeds = Feed.find_with_item_counts(:user => users(:quentin), :tag_filter => { :include => [tag] })
    assert_equal 1, feeds.size
    assert_equal 'Ruby Language', feeds[0].title
    assert_equal 1, feeds[0].item_count.to_i
  end
  
  def test_find_with_item_counts_ignore_deleted_taggings
    # make sure deleted taggings don't get counted
    tag = Tag.find_or_create_by_name('peerworks')
    tagging = Tagging.create(:tag => tag, :tagger => users(:quentin), :taggable => FeedItem.find(1))
    tagging.destroy
    Tagging.create(:tag => tag, :tagger => users(:quentin), :taggable => FeedItem.find(1))
    feeds = Feed.find_with_item_counts(:user => users(:quentin), :tag_filter => { :include => [tag] })
    assert_equal 1, feeds.size
    assert_equal 'Ruby Language', feeds[0].title
    assert_equal 1, feeds[0].item_count.to_i
  end
  
  def test_find_with_item_counts_uses_text_filter
    Feed.expects(:find).with do |type, opts|
      opts[:joins] =~ /MATCH\(content\) AGAINST\('foo' in boolean mode\)/
    end
    Feed.find_with_item_counts(:text_filter => 'foo')
  end
end
