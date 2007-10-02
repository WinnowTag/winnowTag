# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'

class TagPublicationTest < Test::Unit::TestCase
  fixtures :tag_publications, :users, :tags, :bayes_classifiers

  def test_find_feed_items_returns_item_with_tag
    tp = TagPublication.find(1)
    tp.taggings.create(:tag => tp.tag, :taggable => FeedItem.find(1))
    assert_equal([FeedItem.find(1)], tp.find_feed_items)
  end
  
  def test_find_feed_items_returns_items_with_tag
    tp = TagPublication.find(1)
    tp.taggings.create(:tag => tp.tag, :taggable => FeedItem.find(1))
    tp.taggings.create(:tag => tp.tag, :taggable => FeedItem.find(2))
    assert_equal([FeedItem.find(1), FeedItem.find(2)], tp.find_feed_items)
  end
  
  def test_find_feed_items_returns_items_with_classifier_tag
    tp = TagPublication.find(1)
    tp.taggings.create(:tag => tp.tag, :taggable => FeedItem.find(1))
    tp.classifier.taggings.create(:tag => tp.tag, :taggable => FeedItem.find(3))
    assert_equal([FeedItem.find(1), FeedItem.find(3)], tp.find_feed_items)
  end
  
  def test_tag_publication_creation_copies_existing_taggings
    u = users(:quentin)
    u.taggings.create(:tag => Tag('tag1'), :taggable => FeedItem.find(1))
    tag_pub = u.tag_publications.create(:tag => Tag('tag1'), :tag_group => TagGroup.find(:first))
    assert_equal(FeedItem.find(1), tag_pub.taggings.first.taggable)
    assert_equal(Tag('tag1'), tag_pub.taggings.first.tag)
    assert_equal(tag_pub, tag_pub.taggings.first.tagger)
  end
  
  def test_tag_publications_get_their_own_classifier
    u = users(:quentin)
    u.taggings.create(:tag => Tag('tag1'), :taggable => FeedItem.find(1))
    tag_pub = u.tag_publications.create(:tag => Tag('tag1'), :tag_group => TagGroup.find(:first))
    assert_instance_of(BayesClassifier, tag_pub.classifier)
  end
  
  def test_tag_publications_copy_bias_from_publisher
    u = users(:quentin)
    u.classifier.bias = {'tag1' => 1.2}
    u.classifier.save
    u.taggings.create(:tag => Tag('tag1'), :taggable => FeedItem.find(1))
    tag_pub = u.tag_publications.create(:tag => Tag('tag1'), :tag_group => TagGroup.find(:first))
    assert_equal(1.2, tag_pub.classifier.bias['tag1'])
  end
  
  def test_destroying_tag_publication_should_destroy_all_taggings
    tp = TagPublication.find(1)
    tp.taggings.create(:tag => tp.tag, :taggable => FeedItem.find(1))
    assert_difference(Tagging, :count, -1) do
      tp.destroy
    end
  end
  
  def test_destroying_tag_publication_should_destroy_classifier
    tp = TagPublication.find(1)
    assert_difference(BayesClassifier, :count, -1) do
      tp.destroy
    end
  end
  
  def test_create_tag_publication_duplicate_destroys_existing
    tp = TagPublication.find(1)
    
    tp_dup = nil
    assert_difference(TagPublication, :count, 0) do
      tp_dup = TagPublication.create(:tag => tp.tag, :tag_group => tp.tag_group, :publisher => tp.publisher)
    end
    
    assert_nothing_raised(ActiveRecord::RecordNotFound) { TagPublication.find(tp_dup.id) }
    assert_raise(ActiveRecord::RecordNotFound) { TagPublication.find(1) }
  end
  
  def test_tag_publication_requires_publisher
    assert_invalid(TagPublication.new(:tag => Tag('tag'), :tag_group => TagGroup.find(:first)))
  end
  
  def test_tag_publications_requires_tag_group
    assert_invalid(TagPublication.new(:tag => Tag('tag'), :publisher => users(:quentin)))
  end
  
  def test_tag_publications_requires_tag
    assert_invalid(TagPublication.new(:tag_group => TagGroup.find(:first), :publisher => users(:quentin)))
  end
  
  def test_find_by_other_publisher
    user = users(:quentin)
    users_publications = user.tag_publications
    other_publications = TagPublication.find_by_other_publisher(user)
    assert_equal([], users_publications & other_publications)
  end
end
