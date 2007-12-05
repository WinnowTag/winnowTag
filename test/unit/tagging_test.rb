# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
require File.dirname(__FILE__) + '/../test_helper'
Tag

class TaggingTest < Test::Unit::TestCase
  fixtures :taggings, :feeds, :feed_items, :users

  def test_create_tagging
    user = User.find(1)
    feed_item = FeedItem.find(1)
    tag = Tag(user, 'peerworks')
    tagging = Tagging.create(:user => user, :feed_item => feed_item, :tag => tag)
    assert_not_nil tagging
    assert_equal user, tagging.user
    assert_equal tag, tagging.tag
    assert_equal feed_item, tagging.feed_item
    
    tagging = Tagging.find(tagging.id)
    assert_not_nil tagging
    assert_equal user, tagging.user
    assert_equal tag, tagging.tag
    assert_equal feed_item, tagging.feed_item
    assert_equal 1.0, tagging.strength # default strength is 1.0
    
    # now make sure we can reach the tagging through each participant
    assert_not_nil tag.taggings.find(:first, :conditions => "feed_item_id = #{feed_item.id} and user_id = #{user.id}")
    assert_not_nil feed_item.taggings.find(:first, :conditions => "tag_id = #{tag.id} and user_id = #{user.id}")
    assert_not_nil user.taggings.find(:first, :conditions => "tag_id = #{tag.id} and feed_item_id = #{feed_item.id}")
  end
  
  def test_tagging_strength_is_set
    user = User.find(1)
    feed_item = FeedItem.find(1)
    tag = Tag(user, 'peerworks')
    tagging = Tagging.create(:user => user, :feed_item => feed_item, :tag => tag, :strength => 0)
    assert_valid tagging
    assert_equal 0, tagging.strength
  end
  
  def test_strength_outside_0_to_1_is_invalid
    user = User.find(1)
    feed_item = FeedItem.find(1)
    tag = Tag(user, 'peerworks')
    assert_valid Tagging.new(:user => user, :feed_item => feed_item, :tag => tag, :strength => 0.5)
    assert_invalid Tagging.new(:user => user, :feed_item => feed_item, :tag => tag, :strength => 1.1)
    assert_invalid Tagging.new(:user => user, :feed_item => feed_item, :tag => tag, :strength => -0.1)
    # boundaries
    assert_valid Tagging.new(:user => user, :feed_item => feed_item, :tag => tag, :strength => 1)
    assert_valid Tagging.new(:user => user, :feed_item => feed_item, :tag => tag, :strength => 0)
  end
  
  def test_strength_must_be_a_number
    user = User.find(1)
    feed_item = FeedItem.find(1)
    tag = Tag(user, 'peerworks')
    assert_invalid Tagging.new(:user => user, :feed_item => feed_item, :tag => tag, :strength => 'string')
  end
  
  def test_creating_duplicate_deletes_existing
    user = users(:quentin)
    item = FeedItem.find(1)
    tag = Tag(user, 'tag')
    first_tagging = user.taggings.create(:feed_item => item, :tag => tag)
    assert_valid first_tagging
    second_tagging = user.taggings.create(:feed_item => item, :tag => tag)
    assert_valid second_tagging
    assert_raise(ActiveRecord::RecordNotFound) { Tagging.find(first_tagging.id) }
  end
  
  def test_users_is_allowed_manual_and_classifier_taggings_on_an_item
    user = users(:quentin)
    item = FeedItem.find(1)
    tag  = Tag(user, 'tag')
    
    assert_valid first = user.taggings.create(:feed_item => item, :tag => tag)
    assert_valid second = user.taggings.create(:feed_item => item, :tag => tag, :classifier_tagging => true)
    assert_nothing_raised(ActiveRecord::RecordNotFound) { Tagging.find(first.id) }
    assert_nothing_raised(ActiveRecord::RecordNotFound) { Tagging.find(second.id) }
    assert_equal(2, user.taggings.size)
  end
  
  def test_cannot_create_taggings_without_user
    assert_invalid Tagging.new(:feed_item => FeedItem.find(1), :tag => Tag(users(:quentin), 'peerworks'))
  end
  
  def test_cannot_create_taggings_without_feed_item
    assert_invalid Tagging.new(:user => User.find(1), :tag => Tag(users(:quentin), 'peerworks'))
  end
  
  def test_cannot_create_taggings_without_tag
    assert_invalid Tagging.new(:feed_item => FeedItem.find(1), :user => User.find(1))
  end
  
  def test_cannot_create_tagging_with_invalid_tag
    assert_invalid Tagging.new(:feed_item => FeedItem.find(1), :user => User.find(1), :tag => Tag(users(:quentin), ''))
  end
  
  def test_create_with_tag_user_feed_item_is_valid
    assert_valid Tagging.new(:user => User.find(1), :feed_item => FeedItem.find(1), :tag => Tag(users(:quentin), 'peerworks'))
  end
  
  def test_deletion_of_feed_item_deletes_taggings
    user = User.find(1)
    feed_item = FeedItem.find(1)
    tag = Tag(user, 'peerworks')
    tagging = Tagging.create(:user => user, :feed_item => feed_item, :tag => tag)
    feed_item.destroy
    assert_raises(ActiveRecord::RecordNotFound) {Tagging.find(tagging.id)}
  end

  def test_deletion_copies_tagging_to_deleted_taggings_table
    user = User.find(1)
    feed_item = FeedItem.find(1)
    tag = Tag(user, 'peerworks')
    tagging = Tagging.create(:user => user, :feed_item => feed_item, :tag => tag, :strength => 0.75)
    assert_not_nil tagging
    assert_not_nil Tagging.find(tagging.id)
    
    assert_difference(DeletedTagging, :count) do
      tagging.destroy
    end
    
    assert_raise ActiveRecord::RecordNotFound do Tagging.find(tagging.id) end
    assert DeletedTagging.find(:first, :conditions => ['user_id = ? and feed_item_id = ? and tag_id = ? and strength = ?',
                                                        user, feed_item, tag, 0.75])
  end
  
  def test_taggings_are_immutable
    user = users(:quentin)
    item = FeedItem.find(1)
    tag = Tag(user, 'peerworks')
    tagging = Tagging.create(:user => user, :feed_item => item, :tag => tag)
    assert_not_nil tagging
    assert_valid tagging
    assert !tagging.new_record?
    tagging.tag = Tag(user, 'failed')
    assert !tagging.save
    tagging = Tagging.find(tagging.id)
    assert_equal tag, tagging.tag
    assert_equal user, tagging.user
    assert_equal item, tagging.feed_item
  end
   
  def test_borderline_true_for_classifier_tagging_near_0_9
    user = users(:quentin)
    tagging = Tagging.new(:user => user, :tag => Tag(user, 'Tag'), 
                        :feed_item => FeedItem.find(1), :strength => 0.9, 
                        :classifier_tagging => true)
    assert_equal(true, tagging.borderline?)
  end
  
  def test_borderline_requires_classifier_tagging
    user = users(:quentin)
    tagging = Tagging.new(:user => user, :tag => Tag(user, 'Tag'), 
                        :feed_item => FeedItem.find(1), :strength => 0.9)
    assert_equal(false, tagging.borderline?)
  end
  
  def test_classifier_tagging_defaults_to_false
    assert !users(:quentin).taggings.create(:feed_item => FeedItem.find(1), :tag => Tag(users(:quentin), 'tag')).classifier_tagging?  
  end
end
