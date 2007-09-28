# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'

class TaggableTest < Test::Unit::TestCase
  fixtures :users, :bayes_classifiers, :feed_items, :tags
  # we test taggable using FeedItem
  
  def test_each_tagging_by_user
    tag1 = Tag('tag1')
    tag2 = Tag('tag2')
    user = users(:quentin)
    fi = FeedItem.find(1)
    tagging1 = Tagging.create(:tagger => user, :taggable => fi, :tag => tag1)
    tagging2 = Tagging.create(:tagger => user, :taggable => fi, :tag => tag2)
   
    assert_equal [[tag1, tagging1], [tag2, tagging2]], fi.taggings_by_taggers(user) 
  end
  
  def test_each_tagging_by_user_ignores_negative_taggings
    user = users(:quentin)
    fi = FeedItem.find(1)
    tagging1 = Tagging.create(:tagger => user, :taggable => fi, :tag => Tag('tag1'), :strength => 1)
    tagging2 = Tagging.create(:tagger => user, :taggable => fi, :tag => Tag('tag2'), :strength => 0)
    
    assert_equal [[Tag('tag1'), tagging1]], fi.taggings_by_taggers(user) 
  end
  
  def test_each_tagging_by_user_and_classifier_where_user_takes_priority
    tag1 = Tag('tag1')
    tag2 = Tag('tag2')
    user = users(:quentin)
    fi = FeedItem.find(1)
    u_tagging1 = Tagging.create(:tagger => user, :taggable => fi, :tag => tag1)
    u_tagging2 = Tagging.create(:tagger => user, :taggable => fi, :tag => tag2)
    c_tagging1 = Tagging.create(:tagger => user.classifier, :taggable => fi, :tag => tag1)
    c_tagging2 = Tagging.create(:tagger => user.classifier, :taggable => fi, :tag => tag2)
    
    expected = [[tag1, u_tagging1], [tag2, u_tagging2]]
    result = fi.taggings_by_taggers([user, user.classifier]) 
    
    assert_equal expected.size, result.size
    assert_equal expected, result
  end
  
  def test_each_tagging_by_user_and_classifier_where_classifier_tags_float_up
    tag1 = Tag('tag1')
    tag2 = Tag('tag2')
    user = users(:quentin)
    fi = FeedItem.find(1)
    
    u_tagging1 = Tagging.create(:tagger => user, :taggable => fi, :tag => tag1)
    c_tagging1 = Tagging.create(:tagger => user.classifier, :taggable => fi, :tag => tag1)
    c_tagging2 = Tagging.create(:tagger => user.classifier, :taggable => fi, :tag => tag2)
    
    expected = [[tag1, u_tagging1], [tag2, c_tagging2]]
    result = fi.taggings_by_taggers([user, user.classifier])
    
    assert_equal expected.size, result.size
    assert_equal expected, result
  end
  
  def test_each_tagging_by_user_and_classifier_where_classifier_tags_float_up_except_it_is_too_weak
    tag1 = Tag('tag1')
    tag2 = Tag('tag2')
    user = users(:quentin)
    fi = FeedItem.find(1)
    
    u_tagging1 = Tagging.create(:tagger => user, :taggable => fi, :tag => tag1)
    c_tagging1 = Tagging.create(:tagger => user.classifier, :taggable => fi, :tag => tag1)
    c_tagging2 = Tagging.create(:tagger => user.classifier, :taggable => fi, :tag => tag2, :strength => 0.3)
    
    expected = [[tag1, u_tagging1]]
    result = fi.taggings_by_taggers([user, user.classifier])
    
    assert_equal expected.size, result.size
    assert_equal expected, result
  end
  
  def test_each_tagging_by_user_and_classifier_where_classifier_tag_is_overriden_by_negative_tagging
    tag1 = Tag('tag1')
    tag2 = Tag('tag2')
    user = users(:quentin)
    fi = FeedItem.find(1)
    
    u_tagging1 = Tagging.create(:tagger => user, :taggable => fi, :tag => tag1, :strength => 0)
    c_tagging1 = Tagging.create(:tagger => user.classifier, :taggable => fi, :tag => tag1, :strength => 0.99)
    
    expected = []
    result = fi.taggings_by_taggers([user, user.classifier])
    
    assert_equal expected.size, result.size
    assert_equal expected, result
  end
  
  def test_each_tagging_by_user_fails_with_excluded_and_only
    assert_raise ArgumentError do 
      FeedItem.find(1).taggings_by_taggers(users(:quentin), :exclude => 'tag1', :only => 'tag2')
    end
  end
  
  def test_taggings_by_taggers_with_borderline_items
    tag = Tag('tag')
    user = users(:quentin)
    fi = FeedItem.find(1)
    
    c_tagging1 = Tagging.create(:tagger => user.classifier, :taggable => fi, :tag => tag, :strength => 0.89)
    
    expected = [[tag, c_tagging1]]
    result = fi.taggings_by_taggers([user, user.classifier])
    
    assert_equal expected.size, result.size
    assert_equal expected, result    
  end
  
  def test_all_taggings
    tag1 = Tag('tag1')
    user = users(:quentin)
    fi = FeedItem.find(1)

    u_tagging1 = Tagging.create(:tagger => user, :taggable => fi, :tag => tag1, :strength => 0)
    c_tagging1 = Tagging.create(:tagger => user.classifier, :taggable => fi, :tag => tag1, :strength => 0.99)
  
    expected = [[tag1, [u_tagging1, c_tagging1]]]
    result = fi.taggings_by_taggers([user, user.classifier], :all_taggings => true)

    assert_equal expected.size, result.size
    assert_equal expected, result
  end
  
  def test_all_taggings_with_borderline_items
    tag1 = Tag('tag1')
    user = users(:quentin)
    fi = FeedItem.find(1)

    u_tagging1 = Tagging.create(:tagger => user, :taggable => fi, :tag => tag1, :strength => 0)
    c_tagging1 = Tagging.create(:tagger => user.classifier, :taggable => fi, :tag => tag1, :strength => 0.89)
  
    expected = [[tag1, [u_tagging1, c_tagging1]]]
    result = fi.taggings_by_taggers([user, user.classifier], :all_taggings => true)

    assert_equal expected.size, result.size
    assert_equal expected, result
  end
  
  def test_all_taggings_by_tagger_when_tagging_duplicates_exist
    tag1 = Tag('tag1')
    user = users(:quentin)
    fi = FeedItem.find(1)
    
    tagging_1 = Tagging.new(:tagger => user, :taggable => fi, :tag => tag1)
    tagging_2 = Tagging.new(:tagger => user, :taggable => fi, :tag => tag1)
    
    assert tagging_1.send(:create_without_callbacks)
    assert tagging_2.send(:create_without_callbacks)
    
    expected = [[tag1, [tagging_1]]]
    result = fi.taggings_by_taggers(user, :all_taggings => true)
    
    assert_equal expected.size, result.size
    assert_equal expected, result
  end
  
  def test_find_by_tagger_with_caching
    user = users(:quentin)
    fi = FeedItem.find(1)
    tagging_1 = Tagging.new(:tagger => user, :taggable => fi, :tag => Tag('tag1'))
    tagging_2 = Tagging.new(:tagger => user, :taggable => fi, :tag => Tag('tag2'))
    
    fi.taggings.cached_taggings.merge!({user => [tagging_1, tagging_2]})
    assert_equal([tagging_1, tagging_2], fi.taggings.find_by_tagger(user))
  end
  
  def test_find_by_tagger_with_caching_and_tag
    user = users(:quentin)
    fi = FeedItem.find(1)
    tagging_1 = Tagging.new(:tagger => user, :taggable => fi, :tag => Tag('tag1'))
    tagging_2 = Tagging.new(:tagger => user, :taggable => fi, :tag => Tag('tag2'))
    
    fi.taggings.cached_taggings.merge!({user => [tagging_1, tagging_2]})
    assert_equal([tagging_1], fi.taggings.find_by_tagger(user, Tag('tag1')))
  end
  
  def test_find_by_tagger_with_caching_and_multiple_taggers
    user = users(:quentin)
    fi = FeedItem.find(1)
    tagging_1 = Tagging.new(:tagger => user, :taggable => fi, :tag => Tag('tag1'))
    tagging_2 = Tagging.new(:tagger => user, :taggable => fi, :tag => Tag('tag2'))
    tagging_3 = Tagging.new(:tagger => user.classifier, :taggable => fi, :tag => Tag('tag1'))
    tagging_4 = Tagging.new(:tagger => user.classifier, :taggable => fi, :tag => Tag('tag2'))
    
    fi.taggings.cached_taggings.merge!(user => [tagging_1, tagging_2], user.classifier => [tagging_3, tagging_4])
    assert_equal([tagging_1, tagging_2], fi.taggings.find_by_tagger(user))
    assert_equal([tagging_3, tagging_4], fi.taggings.find_by_tagger(user.classifier))
  end
  
  def test_find_by_tagger_with_caching_and_missing_tagger
    user = users(:quentin)
    fi = FeedItem.find(1)
    tagging_1 = Tagging.new(:tagger => user, :taggable => fi, :tag => Tag('tag1'))
    tagging_2 = Tagging.new(:tagger => user, :taggable => fi, :tag => Tag('tag2'))
    tagging_3 = Tagging.create(:tagger => user.classifier, :taggable => fi, :tag => Tag('tag1'))
    tagging_4 = Tagging.create(:tagger => user.classifier, :taggable => fi, :tag => Tag('tag2'))
    
    fi.taggings.cached_taggings.merge!({user => [tagging_1, tagging_2]})
    assert_equal([tagging_3, tagging_4], fi.taggings.find_by_tagger(user.classifier))
  end
end
