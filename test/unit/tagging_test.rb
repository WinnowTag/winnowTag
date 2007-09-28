# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
require File.dirname(__FILE__) + '/../test_helper'

class TaggingTest < Test::Unit::TestCase
  fixtures :taggings, :feeds, :feed_items, :users

  # Replace this with your real tests.
  def test_create_tagging
    user = User.find(1)
    feed_item = FeedItem.find(1)
    tag = Tag.find_or_create_by_name('peerworks')
    tagging = Tagging.create(:tagger => user, :taggable => feed_item, :tag => tag)
    assert_not_nil tagging
    assert_equal user, tagging.tagger
    assert_equal tag, tagging.tag
    assert_equal feed_item, tagging.taggable
    
    tagging = Tagging.find(tagging.id)
    assert_not_nil tagging
    assert_equal user, tagging.tagger
    assert_equal tag, tagging.tag
    assert_equal feed_item, tagging.taggable
    assert_equal 1.0, tagging.strength # default strength is 1.0
    
    # now make sure we can reach the tagging through each participant
    assert_not_nil tag.taggings.find(:first, :conditions => "taggable_type = 'FeedItem' and " +
                                              "taggable_id = #{feed_item.id} and tagger_type = 'User' and " +
                                              "tagger_id = #{user.id}")
    assert_not_nil feed_item.taggings.find(:first, :conditions => "tag_id = #{tag.id} and " +
                                              "tagger_type = 'User' and tagger_id = #{user.id}")
    assert_not_nil user.taggings.find(:first, :conditions => "tag_id = #{tag.id} and " +
                                              "taggable_type = 'FeedItem' and taggable_id = #{feed_item.id}")
  end
  
  def test_tagging_strength_is_set
    user = User.find(1)
    feed_item = FeedItem.find(1)
    tag = Tag.find_or_create_by_name('peerworks')
    tagging = Tagging.create(:tagger => user, :taggable => feed_item, :tag => tag, :strength => 0)
    assert_valid tagging
    assert_equal 0, tagging.strength
  end
  
  def test_strength_outside_0_to_1_is_invalid
    user = User.find(1)
    feed_item = FeedItem.find(1)
    tag = Tag.find_or_create_by_name('peerworks')
    assert_valid Tagging.new(:tagger => user, :taggable => feed_item, :tag => tag, :strength => 0.5)
    assert_invalid Tagging.new(:tagger => user, :taggable => feed_item, :tag => tag, :strength => 1.1)
    assert_invalid Tagging.new(:tagger => user, :taggable => feed_item, :tag => tag, :strength => -0.1)
    # boundaries
    assert_valid Tagging.new(:tagger => user, :taggable => feed_item, :tag => tag, :strength => 1)
    assert_valid Tagging.new(:tagger => user, :taggable => feed_item, :tag => tag, :strength => 0)
  end
  
  def test_strength_must_be_a_number
    user = User.find(1)
    feed_item = FeedItem.find(1)
    tag = Tag.find_or_create_by_name('peerworks')
    assert_invalid Tagging.new(:tagger => user, :taggable => feed_item, :tag => tag, :strength => 'string')
  end
  
  def test_creating_duplicate_deletes_existing
    tagger = users(:quentin)
    item = FeedItem.find(1)
    tag = Tag('tag')
    first_tagging = tagger.taggings.create(:taggable => item, :tag => tag)
    assert_valid first_tagging
    second_tagging = tagger.taggings.create(:taggable => item, :tag => tag)
    assert_valid second_tagging
    assert_raise(ActiveRecord::RecordNotFound) { Tagging.find(first_tagging.id) }
  end
  
  def test_cannot_create_taggings_without_tagger
    assert_invalid Tagging.new(:taggable => FeedItem.find(1), :tag => Tag.find_or_create_by_name('peerworks'))
  end
  
  def test_cannot_create_taggings_without_taggable
    assert_invalid Tagging.new(:tagger => User.find(1), :tag => Tag.find_or_create_by_name('peerworks'))
  end
  
  def test_cannot_create_taggings_without_tag
    assert_invalid Tagging.new(:taggable => FeedItem.find(1), :tagger => User.find(1))
  end
  
  def test_cannot_create_tagging_with_invalid_tag
    assert_invalid Tagging.new(:taggable => FeedItem.find(1), :tagger => User.find(1), :tag => Tag(''))
  end
  
  def test_create_with_tag_tagger_taggable_is_valid
    assert_valid Tagging.new(:tagger => User.find(1), :taggable => FeedItem.find(1), :tag => Tag.find_or_create_by_name('peerworks'))
  end
  
  def test_deletion_of_feed_item_deletes_taggings
    user = User.find(1)
    feed_item = FeedItem.find(1)
    tag = Tag.find_or_create_by_name('peerworks')
    tagging = Tagging.create(:tagger => user, :taggable => feed_item, :tag => tag)
    feed_item.destroy
    assert_raises(ActiveRecord::RecordNotFound) {Tagging.find(tagging.id)}
  end
    
  def test_get_tagging_strength_from_tagger
    user = User.find(1)
    feed_item = FeedItem.find(1)
    tag = Tag.find_or_create_by_name('peerworks')
    Tagging.create(:tagger => user, :taggable => feed_item, :tag => tag, :strength => 0.75)
    assert_equal 0.75, user.tagging_strength_for(tag, feed_item)
    assert_nil user.tagging_strength_for(Tag.find_or_create_by_name('notag'), feed_item)
  end
  
  def test_paranoid_deletion
    user = User.find(1)
    feed_item = FeedItem.find(1)
    tag = Tag.find_or_create_by_name('peerworks')
    tagging = Tagging.create(:tagger => user, :taggable => feed_item, :tag => tag, :strength => 0.75)
    assert_not_nil tagging
    assert_not_nil Tagging.find(tagging.id)
    tagging.destroy
    assert_raise ActiveRecord::RecordNotFound do Tagging.find(tagging.id) end
    assert_not_nil Tagging.find_with_deleted(tagging.id)
    assert Tagging.paranoid?
  end
  
  def test_taggings_are_immutable
    user = users(:quentin)
    item = FeedItem.find(1)
    tag = Tag.find_or_create_by_name('peerworks')
    tagging = Tagging.create(:tagger => user, :taggable => item, :tag => tag)
    assert_not_nil tagging
    assert_valid tagging
    assert !tagging.new_record?
    tagging.tag = Tag.find_or_create_by_name('failed')
    assert !tagging.save
    tagging = Tagging.find(tagging.id)
    assert_equal tag, tagging.tag
    assert_equal user, tagging.tagger
    assert_equal item, tagging.taggable
  end
   
  def test_calls_borderline_on_tagger
    tagger = users(:quentin).classifier
    tagging = Tagging.new(:tagger => tagger, :tag => Tag('Tag'), :taggable => FeedItem.find(1))
    BayesClassifier.any_instance.expects(:borderline_tagging?).with(tagging).returns(true)
    assert tagging.borderline?
  end
  
  def test_returns_false_when_borderline_not_implemented
    tagger = users(:quentin).classifier
    BayesClassifier.any_instance.expects(:borderline_tagging?).never
    BayesClassifier.any_instance.expects(:respond_to?).with(:borderline_tagging?, false).returns(false)
    tagging = Tagging.new(:tagger => tagger, :tag => Tag('Tag'), :taggable => FeedItem.find(1))
    assert !tagging.borderline?
  end
end
