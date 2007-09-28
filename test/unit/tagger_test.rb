# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'

class UserTest < Test::Unit::TestCase  
  fixtures :users, :feed_items, :bayes_classifiers
  
  def test_copy_tag_to_self
    u = users(:quentin)
    u.taggings.create(:taggable => FeedItem.find(1), :tag => Tag('tag1'))
    u.taggings.create(:taggable => FeedItem.find(2), :tag => Tag('tag1'))
    u.taggings.create(:taggable => FeedItem.find(3), :tag => Tag('tag1'))
    
    u.copy_tag(Tag('tag1'), Tag('copy of tag1'))
    assert_equal(3, u.taggings.find_by_tag(Tag('copy of tag1')).size)
    assert_equal(3, u.taggings.find_by_tag(Tag('tag1')).size)
  end
  
  def test_copy_tag_to_another_tagger
    u = users(:quentin)
    u2 = users(:aaron)
    u.taggings.create(:taggable => FeedItem.find(1), :tag => Tag('tag1'))
    u.taggings.create(:taggable => FeedItem.find(2), :tag => Tag('tag1'))
    u.taggings.create(:taggable => FeedItem.find(3), :tag => Tag('tag1'))

    u.copy_tag(Tag('tag1'), Tag('tag1'), u2)
    assert_equal(3, u.taggings.find_by_tag(Tag('tag1')).size)
    assert_equal(3, u2.taggings.find_by_tag(Tag('tag1')).size)
  end
  
  def test_copy_with_the_same_name_raises_error
    u = users(:quentin)
    u.taggings.create(:taggable => FeedItem.find(1), :tag => Tag('tag1'))
    u.taggings.create(:taggable => FeedItem.find(2), :tag => Tag('tag1'))
    u.taggings.create(:taggable => FeedItem.find(3), :tag => Tag('tag1'))
    
    assert_raise(ArgumentError) { u.copy_tag(Tag('tag1'), Tag('tag1')) }
  end
  
  def test_copy_to_other_tagger_when_tag_already_exists_raises_error
    u = users(:quentin)
    u2 = users(:aaron)
    u.taggings.create(:taggable => FeedItem.find(1), :tag => Tag('tag1'))
    u2.taggings.create(:taggable => FeedItem.find(2), :tag => Tag('tag1'))
    
    assert_raise(ArgumentError) { u.copy_tag(Tag('tag1'), Tag('tag1'), u2) }
  end
  
  def test_get_tags_with_count
    u = users(:quentin)
    u2 = users(:aaron)
    fi1 = FeedItem.find(1)
    fi2 = FeedItem.find(4)
    peerworks = Tag.find_or_create_by_name('peerworks')
    test = Tag.find_or_create_by_name('test')
    tag = Tag.find_or_create_by_name('tag')
    Tagging.create(:tagger => u, :taggable => fi1, :tag => peerworks).destroy
    Tagging.create(:tagger => u, :taggable => fi1, :tag => peerworks)
    Tagging.create(:tagger => u, :taggable => fi2, :tag => peerworks)
    Tagging.create(:tagger => u2, :taggable => fi1, :tag => test)
    Tagging.create(:tagger => u, :taggable => fi1, :tag => test)
    Tagging.create(:tagger => u, :taggable => fi1, :tag => tag).destroy

    tags = u.tags_with_count
    assert_equal 2, tags.size
    assert_equal 'peerworks', tags[0].name
    assert_equal 2, tags[0].count.to_i
    assert_equal 'test', tags[1].name
    assert_equal 1, tags[1].count.to_i

    # now check it when limiting it by feed - only counts should change
    tags = u.tags_with_count(:feed_filter => { :include => [2], :exclude => [] })
    assert_equal 2, tags.size
    assert_equal 'peerworks', tags[0].name
    assert_equal 1, tags[0].count.to_i
    assert_equal 'test', tags[1].name
    assert_equal 0, tags[1].count.to_i
  end
 
  def test_tagging_statistics
    u = users(:quentin)
    pw = Tag.find_or_create_by_name('peerworks')
    tag = Tag.find_or_create_by_name('tag')

    assert_equal 0, u.tagging_percentage
    assert_nil u.last_tagging_on
    assert_equal 0, u.average_taggings_per_item
    assert_equal 0, u.number_of_tagged_items

    assert Tagging.create(:tagger => u, :taggable => FeedItem.find(1), :tag => pw)
    assert last = Tagging.create(:tagger => u, :taggable => FeedItem.find(2), :tag => pw)

    assert_equal 50, u.tagging_percentage
    assert_equal last.created_on.to_s, u.last_tagging_on.to_s
    assert_equal 1, u.average_taggings_per_item
    assert_equal 2, u.number_of_tagged_items

    Tagging.create(:tagger => u, :taggable => FeedItem.find(1), :tag => tag)
    last = Tagging.create(:tagger => u, :taggable => FeedItem.find(2), :tag => tag)

    assert_equal 50, u.tagging_percentage
    assert_equal last.created_on.to_s, u.last_tagging_on.to_s
    assert_equal 2, u.average_taggings_per_item
    assert_equal 2, u.number_of_tagged_items

    Tagging.create(:tagger => u, :taggable => FeedItem.find(3), :tag => pw)
    last = Tagging.create(:tagger => u, :taggable => FeedItem.find(4), :tag => pw)

    assert_equal 100, u.tagging_percentage
    assert_equal last.created_on.to_s, u.last_tagging_on.to_s
    assert_equal 1.5, u.average_taggings_per_item
    assert_equal 4, u.number_of_tagged_items

    User.find_by_login('quentin').taggings.clear
    assert_equal 0, u.tagging_percentage
    assert_nil u.last_tagging_on
    assert_equal 0, u.average_taggings_per_item
    assert_equal 0, u.number_of_tagged_items
  end
end