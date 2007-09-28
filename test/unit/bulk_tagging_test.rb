require File.dirname(__FILE__) + '/../test_helper'

class BulkTaggingTest < Test::Unit::TestCase
  fixtures :bulk_taggings, :feed_items, :feeds, :users

  # Replace this with your real tests.
  def test_bulk_tagging
    feed = Feed.find(1)
    user = User.find(1)
    tag = Tag.find_or_create_by_name('incredible bulk')
    bulk_mod = BulkTagging.create(:filter => Feed.find(1), :tagger => user, :tag => tag, :strength => 1.0)
    
    assert_equal BulkTagging::FeedFilter, bulk_mod.filter_type
    assert_equal 1, bulk_mod.filter_value
    
    feed.feed_items.each do |fi|
      tagging = fi.taggings.find_by_tagger(user).first
      assert_equal tag, tagging.tag
      assert_equal 1.0, tagging.strength
      assert_equal user, tagging.tagger
      assert_equal bulk_mod, tagging.metadata
    end
  end
  
  def test_bulk_tagging_leaves_existing_tags
    feed = Feed.find(1)
    fi = FeedItem.find(1)
    user = User.find(1)
    tag = Tag.find_or_create_by_name('incredible bulk')
    existing = Tagging.create(:tagger => user, :taggable => fi, :tag => tag, :strength => 0)
    
    bulk_mod = BulkTagging.create(:filter => Feed.find(1), :tagger => user, :tag => tag, :strength => 1.0)
    
    assert_not_nil Tagging.find(existing.id)
    taggings = fi.taggings.find_by_tagger(user)
    assert_equal 1, taggings.size
    assert_equal 0, taggings.first.strength
    assert_equal 2, bulk_mod.taggings.size
  end
  
  def test_bulk_tagging_with_exclusive_overrides_all_existing_taggings
    feed = Feed.find(1)
    fi = FeedItem.find(1)
    user = User.find(1)
    bulk_tag = Tag.find_or_create_by_name('bulk')
    tag1 = Tag.find_or_create_by_name('existing')
    tag2 = Tag.find_or_create_by_name('existing2')
    existing1 = Tagging.create(:tagger => user, :taggable => fi, :tag => tag1, :strength => 1)
    existing2 = Tagging.create(:tagger => user, :taggable => fi, :tag => tag2, :strength => 1)
    
    bulk_mod = BulkTagging.create(:filter => Feed.find(1), :tagger => user, :tag => bulk_tag, :strength => 1.0, :exclusive => true)
    
    assert_raise(ActiveRecord::RecordNotFound) {Tagging.find(existing1.id)}
    assert_raise(ActiveRecord::RecordNotFound) {Tagging.find(existing2.id)}
    
    feed.feed_items.each do |fi|
      assert_equal 1, fi.taggings.find_by_tagger(user).size
      tagging = fi.taggings.find_by_tagger(user).first
      assert_equal bulk_tag, tagging.tag
    end
  end
  
  def test_bulk_moderation_overrides_existing_bulk_taggings
    feed = Feed.find(1)
    user = User.find(1)
    tag = Tag.find_or_create_by_name('incredible bulk')
    bulk_mod = BulkTagging.create(:filter => Feed.find(1), :tagger => user, :tag => tag, :strength => 1.0)

    assert_equal BulkTagging::FeedFilter, bulk_mod.filter_type
    assert_equal 1, bulk_mod.filter_value

    feed.feed_items.each do |fi|
      tagging = fi.taggings.find_by_tagger(user).first
      assert_equal tag, tagging.tag
      assert_equal 1.0, tagging.strength
      assert_equal user, tagging.tagger
      assert_equal bulk_mod, tagging.metadata
    end
    
    bulk_mod = BulkTagging.create(:filter => Feed.find(1), :tagger => user, :tag => tag, :strength => 0)

    assert_equal BulkTagging::FeedFilter, bulk_mod.filter_type
    assert_equal 1, bulk_mod.filter_value

    feed.feed_items.each do |fi|
      tagging = fi.taggings.find_by_tagger(user).first
      assert_equal tag, tagging.tag
      assert_equal 0, tagging.strength
      assert_equal user, tagging.tagger
      assert_equal bulk_mod, tagging.metadata
    end
  end
  
  def test_bulk_tagging_validations
    feed = Feed.find(1)
    user = User.find(1)
    tag = Tag.find_or_create_by_name('incredible bulk')
    # without filter
    bulk = BulkTagging.create(:tagger => user, :tag => tag)
    assert_invalid bulk
    
    # without tagger
    bulk = BulkTagging.create(:filter => feed, :tag => tag)
    assert_invalid bulk
    
    # without tag
    bulk = BulkTagging.create(:tagger => user, :filter => feed)
    assert_invalid bulk
  end
  
  def test_bulk_tagging_with_hash_of_tags
    feed = Feed.find(1)
    user = User.find(1)
    bulk_mod = BulkTagging.create(:filter => Feed.find(1), :tagger => user, :tags => {'bulk' => 1, 'hulk' => 0})
    
    assert_equal BulkTagging::FeedFilter, bulk_mod.filter_type
    assert_equal 1, bulk_mod.filter_value
    
    feed.feed_items.each do |fi|
      taggings = fi.taggings.find_by_tagger(user)
      tagging = taggings.first
      assert_equal 'bulk', tagging.tag.name
      assert_equal 1.0, tagging.strength
      assert_equal user, tagging.tagger
      assert_equal bulk_mod, tagging.metadata
      
      tagging = taggings[1]
      assert_equal 'hulk', tagging.tag.name
      assert_equal 0, tagging.strength
      assert_equal user, tagging.tagger
      assert_equal bulk_mod, tagging.metadata
    end
  end
  
  def test_bulk_tagging_is_immutable
    feed = Feed.find(1)
    user = User.find(1)
    bulk_mod = BulkTagging.create(:filter => Feed.find(1), :tagger => user, :tags => {'bulk' => 1, 'hulk' => 0})
    assert_equal BulkTagging::FeedFilter, bulk_mod.filter_type
    assert_equal 1, bulk_mod.filter_value
    assert !bulk_mod.new_record?
    assert !bulk_mod.save
  end
end
