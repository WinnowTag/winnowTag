# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
require File.dirname(__FILE__) + '/../test_helper'

class RenameTaggingTest < Test::Unit::TestCase
  fixtures :rename_taggings, :users, :taggings, :feed_items, :tags

  # Replace this with your real tests.
  def test_rename_validations
    old_tag = Tag.find_or_create_by_name('old')
    new_tag = Tag.find_or_create_by_name('new')
    rename_tagging = RenameTagging.new :old_tag => old_tag, :new_tag => new_tag, :tagger => users(:quentin)
    assert_valid rename_tagging
    assert_equal old_tag, rename_tagging.old_tag
    assert_equal new_tag, rename_tagging.new_tag
    
    rename_tagging = RenameTagging.new :old_tag => old_tag, :new_tag => new_tag
    assert_invalid rename_tagging
    
    rename_tagging = RenameTagging.new :old_tag => old_tag, :tagger => users(:quentin)
    assert_invalid rename_tagging
    
    rename_tagging = RenameTagging.new :new_tag => new_tag, :tagger => users(:quentin)
    assert_invalid rename_tagging
    
    rename_tagging = RenameTagging.new :new_tag => Tag.find_or_create_by_name(nil), :old_tag => old_tag, :tagger => users(:quentin)
    assert_invalid rename_tagging
    
    rename_tagging = RenameTagging.new :new_tag => old_tag, :old_tag => old_tag, :tagger => users(:quentin)
    assert_invalid rename_tagging
  end
  
  def test_rename_tagging_is_immutable
    old_tag = Tag.find_or_create_by_name('old')
    new_tag = Tag.find_or_create_by_name('new')
    rename_tagging = RenameTagging.create :old_tag => old_tag, :new_tag => new_tag, :tagger => users(:quentin)
    assert !rename_tagging.new_record?
    assert !rename_tagging.save
  end
  
  def test_rename_with_no_existing_taggings
    tagger = users(:quentin)
    original_tagging_count = Tagging.count
    old_tag = Tag.find_or_create_by_name('old')
    new_tag = Tag.find_or_create_by_name('new')
    rename_tagging = RenameTagging.create :old_tag => old_tag, :new_tag => new_tag, :tagger => tagger
    assert_equal original_tagging_count, Tagging.count
    assert rename_tagging.taggings.empty?
    assert_equal "Renamed 0 tags from old to new.", rename_tagging.message
  end
  
  def test_rename_with_no_target_taggings
    tagger = users(:quentin)
    old_tag = Tag.find_or_create_by_name('old')
    new_tag = Tag.find_or_create_by_name('new')
    Tagging.create(:tagger => tagger, :taggable => FeedItem.find(1), :tag => old_tag, :strength => 1)
    Tagging.create(:tagger => tagger, :taggable => FeedItem.find(2), :tag => old_tag, :strength => 0)
    assert_equal 2, tagger.taggings.find_by_tag(old_tag).size
    assert tagger.taggings.find_by_tag(new_tag).empty?
    
    rename_tagging = RenameTagging.create :old_tag => old_tag, :new_tag => new_tag, :tagger => tagger
    assert_equal 2, rename_tagging.taggings.size
    assert tagger.taggings.find_by_tag(old_tag).empty?
    assert_equal 2, tagger.taggings.find_by_tag(new_tag).size
    assert_equal "Renamed 2 tags from old to new.", rename_tagging.message
    
    tagger.taggings.find_by_tag(new_tag).each do |tagging|
      assert_equal rename_tagging, tagging.metadata
      if tagging.taggable_id == 1
        assert_equal 1.0, tagging.strength
      elsif tagging.taggable_id == 2
        assert_equal 0, tagging.strength
      else
        flunk "Got a tagging which should not exist: #{tagging.inspect}"
      end
    end
  end
  
  def test_rename_with_target_taggings
    tagger = users(:quentin)
    old_tag = Tag.find_or_create_by_name('old')
    new_tag = Tag.find_or_create_by_name('new')
    Tagging.create(:tagger => tagger, :taggable => FeedItem.find(1), :tag => old_tag, :strength => 1)
    Tagging.create(:tagger => tagger, :taggable => FeedItem.find(2), :tag => old_tag, :strength => 0)
    Tagging.create(:tagger => tagger, :taggable => FeedItem.find(3), :tag => old_tag, :strength => 1)
    Tagging.create(:tagger => tagger, :taggable => FeedItem.find(3), :tag => new_tag, :strength => 0)
    Tagging.create(:tagger => tagger, :taggable => FeedItem.find(4), :tag => new_tag, :strength => 1)
    
    assert_equal 3, tagger.taggings.find_by_tag(old_tag).size
    assert_equal 2, tagger.taggings.find_by_tag(new_tag).size
    
    rename_tagging = RenameTagging.create :old_tag => old_tag, :new_tag => new_tag, :tagger => tagger
    assert_equal 2, rename_tagging.taggings.size
    assert_equal 1, tagger.taggings.find_by_tag(old_tag).size
    assert_equal 4, tagger.taggings.find_by_tag(new_tag).size
    assert_equal "Renamed 2 tags from old to new. Left 1 old tag untouched because new already exists on the item.", rename_tagging.message
    
    old_tagging = tagger.taggings.find_by_tag(old_tag).first
    assert_not_nil old_tagging
    assert_equal 1, old_tagging.strength
    assert_equal 3, old_tagging.taggable_id
    
    tagger.taggings.find_by_tag(new_tag).each do |tagging|
      if tagging.taggable_id == 1
        assert_equal 1.0, tagging.strength
      elsif tagging.taggable_id == 2
        assert_equal 0, tagging.strength
      elsif tagging.taggable_id == 3
        assert_equal 0, tagging.strength
      elsif tagging.taggable_id == 4
        assert_equal 1, tagging.strength
      else
        flunk "Got a tagging which should not exist: #{tagging.inspect}"
      end
    end
  end
  
  def test_singular_message_pluralization
    tagger = users(:quentin)
    old_tag = Tag.find_or_create_by_name('old_tag')
    new_tag = Tag.find_or_create_by_name('new_tag')
    Tagging.create(:tagger => tagger, :taggable => FeedItem.find(1), :tag => old_tag, :strength => 1)
    rename_tagging = RenameTagging.create :old_tag => old_tag, :new_tag => new_tag, :tagger => tagger
    assert_equal "Renamed 1 tag from old_tag to new_tag.", rename_tagging.message
  end
  
  def test_renaming_also_renames_classifier_taggings
    tagger = users(:quentin)
    old_tag = Tag.find_or_create_by_name('old')
    new_tag = Tag.find_or_create_by_name('new')
    Tagging.create(:tagger => tagger, :taggable => FeedItem.find(1), :tag => old_tag, :strength => 1)
    Tagging.create(:tagger => tagger.classifier, :taggable => FeedItem.find(1), :tag => old_tag, :strength => 0.99)
    Tagging.create(:tagger => tagger.classifier, :taggable => FeedItem.find(2), :tag => old_tag, :strength => 0.98)
    Tagging.create(:tagger => tagger.classifier, :taggable => FeedItem.find(3), :tag => old_tag, :strength => 0.97)
    Tagging.create(:tagger => tagger.classifier, :taggable => FeedItem.find(4), :tag => old_tag, :strength => 0.96)
    
    rename_tagging = RenameTagging.create(:old_tag => old_tag, :new_tag => new_tag, :tagger => tagger)
    assert_equal "Renamed 5 tags from old to new.", rename_tagging.message
    
    assert_equal 1, tagger.taggings.size
    assert_equal 4, tagger.classifier.taggings.size
    
    assert_equal 1, tagger.taggings.first.taggable_id
    assert_equal 1.0, tagger.taggings.first.strength
    assert_equal new_tag, tagger.taggings.first.tag
    
    tagger.classifier.taggings do |tagging|
      assert_equal new_tag, tagging.tag
      
      if tagging.taggable_id == 1
        assert_equal 0.99, tagging.strength
      elsif tagging.taggable_id == 2
        assert_equal 0.98, tagging.strength
      elsif tagging.taggable_id == 3
        assert_equal 0.97, tagging.strength
      elsif tagging.taggable_id == 4
        assert_equal 0.96, tagging.strength
      else
        flunk "Got a tagging which should not exist: #{tagging.inspect}"
      end
    end
  end
  
  def test_renaming_with_classifier_taggings_when_target_exists
    tagger = users(:quentin)
    old_tag = Tag.find_or_create_by_name('old')
    new_tag = Tag.find_or_create_by_name('new')
    Tagging.create(:tagger => tagger, :taggable => FeedItem.find(1), :tag => old_tag, :strength => 1)
    Tagging.create(:tagger => tagger.classifier, :taggable => FeedItem.find(1), :tag => old_tag, :strength => 0.99)
    Tagging.create(:tagger => tagger.classifier, :taggable => FeedItem.find(2), :tag => old_tag, :strength => 0.98)
    Tagging.create(:tagger => tagger.classifier, :taggable => FeedItem.find(3), :tag => old_tag, :strength => 0.97)
    Tagging.create(:tagger => tagger.classifier, :taggable => FeedItem.find(4), :tag => old_tag, :strength => 0.96)
    
    Tagging.create(:tagger => tagger, :taggable => FeedItem.find(2), :tag => new_tag, :strength => 1)
    Tagging.create(:tagger => tagger.classifier, :taggable => FeedItem.find(1), :tag => new_tag, :strength => 0.99)
    Tagging.create(:tagger => tagger.classifier, :taggable => FeedItem.find(2), :tag => new_tag, :strength => 0.98)
    Tagging.create(:tagger => tagger.classifier, :taggable => FeedItem.find(4), :tag => new_tag, :strength => 0.96)
    
    rename_tagging = RenameTagging.create(:old_tag => old_tag, :new_tag => new_tag, :tagger => tagger)
    assert_equal "Renamed 2 tags from old to new.", rename_tagging.message
    
    assert_equal 2, tagger.taggings.size
    assert_equal 4, tagger.classifier.taggings.size

    user_taggings = tagger.taggings.sort {|a, b| a.taggable_id <=> b.taggable_id}
    assert_equal 1, user_taggings.first.taggable_id
    assert_equal 1.0, user_taggings.first.strength
    assert_equal new_tag, user_taggings.first.tag
    assert_equal 2, user_taggings[1].taggable_id
    assert_equal 1.0, user_taggings[1].strength
    assert_equal new_tag, user_taggings[1].tag

    tagger.classifier.taggings do |tagging|
      assert_equal new_tag, tagging.tag

      if tagging.taggable_id == 1
        assert_equal 0.99, tagging.strength
      elsif tagging.taggable_id == 2
        assert_equal 0.98, tagging.strength
      elsif tagging.taggable_id == 3
        assert_equal 0.97, tagging.strength
      elsif tagging.taggable_id == 4
        assert_equal 0.96, tagging.strength
      else
        flunk "Got a tagging which should not exist: #{tagging.inspect}"
      end
    end
  end
end
