# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'

class TagTest < Test::Unit::TestCase
  fixtures :tags, :users

  # Replace this with your real tests.
  def test_cant_create_duplicate_tags
    assert_valid Tag.create(:user => users(:quentin), :name => 'foo')
    assert_invalid Tag.new(:user => users(:quentin), :name => 'foo')
  end
  
  def test_cant_create_empty_tags
    assert_invalid Tag.new(:user => users(:quentin), :name => '')
  end
  
  def test_case_sensitive
    tag1 = Tag(users(:quentin), 'TAG1')
    tag2 = Tag(users(:quentin), 'tag1')
    assert_not_equal tag1, tag2
  end
  
  def test_tag_function
    tag = Tag(users(:quentin), 'tag1')
    assert tag.is_a?(Tag)
    assert_equal 'tag1', tag.name
    assert !tag.new_record?
    
    tag2 = Tag(users(:quentin), tag)
    assert_equal tag, tag2
  end
  
  def test_tag_to_s_returns_name
    tag = Tag(users(:quentin), 'tag1')
    assert_equal('tag1', tag.to_s)
  end
  
  def test_tag_to_param_returns_name
    tag = Tag(users(:quentin), 'tag1')
    assert_equal('tag1', tag.to_param)
  end
  
  def test_sorting
    tag1 = Tag(users(:quentin), 'aaa')
    tag2 = Tag(users(:quentin), 'bbb')
    assert_equal([tag1, tag2], [tag1, tag2].sort)
    assert_equal([tag1, tag2], [tag2, tag1].sort)
  end
  
  def test_sorting_is_case_insensitive
    tag1 = Tag(users(:quentin), 'aaa')
    tag2 = Tag(users(:quentin), 'Abb')
    assert_equal([tag1, tag2], [tag1, tag2].sort)
    assert_equal([tag1, tag2], [tag2, tag1].sort)
  end
  
  def test_sorting_with_non_tag_raises_exception
    tag = Tag(users(:quentin), 'tag')
    assert_raise(ArgumentError) { tag <=> 42 }
  end
  
  def test_two_tags_belonging_to_different_users_are_different
    assert_not_equal(Tag(users(:quentin), "tag"), Tag(users(:aaron), "tag"))    
  end
  
  def test_copy_tag_to_self
    u = users(:quentin)
    tag = Tag(u, 'tag1')
    copy = Tag(u, 'copy of tag1')
    u.taggings.create(:feed_item => FeedItem.find(1), :tag => tag)
    u.taggings.create(:feed_item => FeedItem.find(2), :tag => tag)
    u.taggings.create(:feed_item => FeedItem.find(3), :tag => tag)
    
    tag.copy(copy)
    assert_equal(3, u.taggings.find_by_tag(copy).size)
    assert_equal(3, u.taggings.find_by_tag(tag).size)
  end
  
  def test_copy_tag_to_another_user
    u = users(:quentin)
    u2 = users(:aaron)
    tag_quent = Tag(u, 'tag1')
    tag_aaron = Tag(u2, 'tag1')
    u.taggings.create(:feed_item => FeedItem.find(1), :tag => tag_quent)
    u.taggings.create(:feed_item => FeedItem.find(2), :tag => tag_quent)
    u.taggings.create(:feed_item => FeedItem.find(3), :tag => tag_quent)

    tag_quent.copy(tag_aaron)
    assert_equal(3, u.taggings.find_by_tag(tag_quent).size)
    assert_equal(3, u2.taggings.find_by_tag(tag_aaron).size)
  end
  
  def test_copy_with_the_same_name_raises_error
    u = users(:quentin)
    tag = Tag(u, 'tag1')
    u.taggings.create(:feed_item => FeedItem.find(1), :tag => tag)
    u.taggings.create(:feed_item => FeedItem.find(2), :tag => tag)
    u.taggings.create(:feed_item => FeedItem.find(3), :tag => tag)
    
    assert_raise(ArgumentError) { tag.copy(tag) }
  end
  
  def test_copy_to_other_user_when_tag_already_exists_raises_error
    u = users(:quentin)
    u2 = users(:aaron)
    u.taggings.create(:feed_item => FeedItem.find(1), :tag => Tag(u, 'tag1'))
    u2.taggings.create(:feed_item => FeedItem.find(2), :tag => Tag(u, 'tag1'))
    
    assert_raise(ArgumentError) { Tag(u, 'tag1').copy(Tag(u, 'tag1')) }
  end
  
  def test_copying_a_tag_skips_classifier_taggings
    u = users(:quentin)
    tag = Tag(u, 'tag1')
    copy = Tag(u, 'copy of tag1')
    u.taggings.create(:feed_item => FeedItem.find(1), :tag => tag)
    u.taggings.create(:feed_item => FeedItem.find(2), :tag => tag, :classifier_tagging => true)
    
    tag.copy(copy)
    assert_equal(3, u.taggings.size)
    assert_equal(1, u.classifier_taggings.size)
  end
  
  def test_merge_into_another_tag
    u = users(:quentin)
    old = Tag(u, 'old')
    new_tag = Tag(u, 'new')
    
    u.taggings.create(:feed_item => FeedItem.find(1), :tag => old)
    u.taggings.create(:feed_item => FeedItem.find(2), :tag => new_tag)
    
    old.merge(new_tag)
    
    assert_equal([], old.taggings)
    assert_equal([1, 2], new_tag.taggings.map(&:feed_item_id).sort)
  end
  
  def test_merge_when_tag_exists_on_item
    u = users(:quentin)
    old = Tag(u, 'old')
    new_tag = Tag(u, 'new')
    
    u.taggings.create(:feed_item => FeedItem.find(1), :tag => old)
    u.taggings.create(:feed_item => FeedItem.find(1), :tag => new_tag)
    
    old.merge(new_tag)
    
    assert_equal([], old.taggings.map(&:feed_item_id))
    assert_equal([1], new_tag.taggings.map(&:feed_item_id))    
  end
end
