# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'
require "tag"

class FeedItemTest < Test::Unit::TestCase
  fixtures :feed_items, :users
    
  def test_getting_content_when_content_returns_empty_content
    feed_item = FeedItem.new    
    assert_nil feed_item.content.title
    assert_nil feed_item.content.link
  end
  
  # Tests for the find_with_filters method
  def test_find_with_show_untagged_returns_all_items
    feed_items = FeedItem.find_with_filters(:user => users(:quentin), :order => 'feed_items.id ASC')
    assert_equal FeedItem.find(1, 2, 3, 4), feed_items
  end
  
  def test_find_includes_borderline_items
    user = users(:quentin)
    tag2 = Tag(user, 'tag2')
    Tagging.create(:user => user, :feed_item => FeedItem.find(3), :tag => tag2, :classifier_tagging => true)
    Tagging.create(:user => user, :feed_item => FeedItem.find(4), :tag => tag2, :strength => 0.89, :classifier_tagging => true)
        
    expected = FeedItem.find(3, 4)
    actual = FeedItem.find_with_filters(:user => user, :tag_ids => tag2.id.to_s, :order => 'feed_items.id ASC')    
    assert_equal expected, actual
  end
  
  def test_find_with_negatives_includes_negativey_tagged_items
    user = users(:quentin)
    tag = Tag(user, 'tag')
    Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag)
    Tagging.create(:user => user, :feed_item => FeedItem.find(4), :tag => tag, :strength => 0)
    
    expected = FeedItem.find(2, 4)
    assert_equal(expected, FeedItem.find_with_filters(:user => user, :tag_ids => tag.id.to_s, :manual_taggings => true, :order => 'feed_items.id asc'))
  end
  
  def test_find_with_tag_filter_should_only_return_items_with_that_tag
    user = users(:quentin)
    tag = Tag(user, 'tag1')
    Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag)
    
    assert_equal [FeedItem.find(2)], FeedItem.find_with_filters(:user => user, :tag_ids => tag.id.to_s)
  end
  
  def test_find_with_multiple_tag_filters_should_only_return_items_with_those_tags
    user = users(:quentin)
    tag = Tag(user, 'tag1')
    tag2 = Tag(user, 'tag2')
    Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag)
    Tagging.create(:user => user, :feed_item => FeedItem.find(3), :tag => tag2)
    
    expected = [FeedItem.find(2), FeedItem.find(3)]
    actual = FeedItem.find_with_filters(:user => users(:quentin), :tag_ids => "#{tag.id},#{tag2.id}", :order => 'feed_items.id ASC')
    assert_equal expected, actual
  end
  
  def test_find_with_tag_filter_excludes_negative_taggings
    user = users(:quentin)
    tag = Tag(user, 'tag1')
    Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag)
    Tagging.create(:user => user, :feed_item => FeedItem.find(3), :tag => tag, :strength => 0)

    assert_equal [FeedItem.find(2)], FeedItem.find_with_filters(:user => user, :tag_ids => tag.id.to_s)
  end  

  def test_find_with_tag_filter_negative_taggings_exclude_positive_classifier_taggings
    user = users(:quentin)
    tag = Tag(user, 'tag1')
    Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag)
    Tagging.create(:user => user, :feed_item => FeedItem.find(3), :tag => tag, :classifier_tagging => true)
    Tagging.create(:user => user, :feed_item => FeedItem.find(3), :tag => tag, :strength => 0)

    assert_equal [FeedItem.find(2)], FeedItem.find_with_filters(:user => user, :tag_ids => tag.id.to_s)
  end
  
  def test_find_with_tag_filter_should_ignore_other_users_tags
    user = users(:quentin)
    aaron = users(:aaron)
    tag = Tag(user, 'tag1')
    atag = Tag(aaron, 'tag1')
    
    Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag)
    Tagging.create(:user => users(:aaron), :feed_item => FeedItem.find(3), :tag => atag)

    assert_equal [FeedItem.find(2)], FeedItem.find_with_filters(:user => user, :tag_ids => tag.id.to_s)
  end
  
  def test_find_with_tag_filter_should_include_classifier_tags
    user = users(:quentin)
    tag = Tag(user, 'tag1')
    Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag)
    Tagging.create(:user => user, :feed_item => FeedItem.find(3), :tag => tag, :classifier_tagging => true)

    assert_equal FeedItem.find(2, 3), FeedItem.find_with_filters(:user => user, :tag_ids => tag.id.to_s, :order => 'feed_items.id ASC')
  end
  
  def test_find_with_excluded_tag_should_return_items_not_tagged_with_that_tag
    user = users(:quentin)
    tag1 = Tag(user, 'tag1')
    tag2 = Tag(user, 'tag2')
    Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag1)
    Tagging.create(:user => user, :feed_item => FeedItem.find(3), :tag => tag2)
  
    user.tag_exclusions.create! :tag_id => tag1.id
    
    expected = [FeedItem.find(3)]
    assert_equal expected, FeedItem.find_with_filters(:user => user, :order => 'feed_items.id ASC')
  end
  
  def test_find_with_multiple_excluded_tags_should_return_items_not_tagged_with_those_tags
    user = users(:quentin)
    tag1 = Tag(user, 'tag1')
    tag2 = Tag(user, 'tag2')
    tag3 = Tag(user, 'tag3')
    Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag1)
    Tagging.create(:user => user, :feed_item => FeedItem.find(3), :tag => tag2)
    Tagging.create(:user => user, :feed_item => FeedItem.find(4), :tag => tag3)
  
    user.tag_exclusions.create! :tag_id => tag1.id
    user.tag_exclusions.create! :tag_id => tag2.id
    
    expected = FeedItem.find(1, 4)
    assert_equal expected, FeedItem.find_with_filters(:user => user, :order => 'feed_items.id ASC')
  end
  
  def test_find_with_excluded_tag_should_return_items_not_tagged_with_that_tag
    user = users(:quentin)
    tag1 = Tag(user, 'tag1')
    tag2 = Tag(user, 'tag2')
    Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag1)
    Tagging.create(:user => user, :feed_item => FeedItem.find(3), :tag => tag2)
  
    user.tag_exclusions.create! :tag_id => tag1.id
    
    expected = FeedItem.find(1, 3, 4)
    assert_equal expected, FeedItem.find_with_filters(:user => user, :order => 'feed_items.id ASC')
  end
  
  def test_find_with_included_and_excluded_tags_should_return_items_tagged_with_included_tag_and_not_the_excluded_tag
    user = users(:quentin)
    tag1 = Tag(user, 'tag1')
    tag2 = Tag(user, 'tag2')
    Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag1)
    Tagging.create(:user => user, :feed_item => FeedItem.find(3), :tag => tag1)
    Tagging.create(:user => user, :feed_item => FeedItem.find(3), :tag => tag2)
  
    user.tag_exclusions.create! :tag_id => tag2.id
    
    expected = [FeedItem.find(2)]
    assert_equal expected, FeedItem.find_with_filters(:user => user, :tag_ids => tag1.id.to_s, :order => 'feed_items.id ASC')
  end
  
  def test_find_with_feed_filters_should_return_only_tagged_items_from_the_included_feed
    user = users(:quentin)
    tag1 = Tag(user, 'tag1')
    
    expected = FeedItem.find(1, 2, 3)
    actual = FeedItem.find_with_filters(:user => user, :feed_ids => "1", :order => 'feed_items.id ASC')
    assert_equal expected, actual
  end
  
  def test_find_with_multiple_feed_filters_and_show_untagged_should_return_only_items_from_the_included_feeds
    feed_item5 = FeedItem.create!(:feed_id => 3, :unique_id => "fifth", :link => "http://fifth")
    
    expected = FeedItem.find(1, 2, 3, 4)
    actual = FeedItem.find_with_filters(:user => users(:quentin), :feed_ids => "1,2", :order => 'feed_items.id ASC')
    assert_equal expected, actual
  end
      
  # def test_find_with_feed_set_to_always_include_returns_all_tagged_items
  #   user = users(:quentin)
  #   tag1 = Tag(user, 'tag1')
  #   Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag1)
  #   
  #   view = users(:quentin).views.create!
  #   view.add_feed :always_include, 2
  # 
  #   expected = FeedItem.find(2, 4)
  #   actual = FeedItem.find_with_filters(:view => view, :order => 'feed_items.id ASC')
  #   assert_equal expected, actual
  # end
  
  # def test_find_with_feed_set_to_always_include_and_show_untagged_items_returns_all_items
  #   user = users(:quentin)
  #   tag1 = Tag(user, 'tag1')
  #   Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag1)
  #   
  #   view = users(:quentin).views.create! :show_untagged => true
  #   view.add_feed :always_include, 2
  # 
  #   expected = FeedItem.find(1, 2, 3, 4)
  #   actual = FeedItem.find_with_filters(:view => view, :order => 'feed_items.id ASC')
  #   assert_equal expected, actual
  # end
  
  # def test_find_with_feed_set_to_include_and_feed_set_to_always_include_and_show_untagged_returns_all_items_from_the_include_and_always_included_feed
  #   feed_item5 = FeedItem.create!(:feed_id => 3, :unique_id => "fifth", :link => "http://fifth")
  # 
  #   user = users(:quentin)
  #   tag1 = Tag(user, 'tag1')
  #   Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag1)
  # 
  #   view = users(:quentin).views.create! :show_untagged => true
  #   view.add_feed :include, 1
  #   view.add_feed :always_include, 2
  # 
  #   expected = FeedItem.find(1, 2, 3, 4)
  #   actual = FeedItem.find_with_filters(:view => view, :order => 'feed_items.id ASC')
  #   assert_equal expected, actual
  # end
  
  # def test_find_with_feed_set_to_include_and_feed_set_to_always_include_and_show_untagged_returns_all_items_from_the_always_included_feed_and_tagged_items_from_the_included_feed
  #   feed_item5 = FeedItem.create!(:feed_id => 3, :unique_id => "fifth", :link => "http://fifth")
  # 
  #   user = users(:quentin)
  #   tag1 = Tag(user, 'tag1')
  #   Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag1)
  # 
  #   view = users(:quentin).views.create!
  #   view.add_feed :include, 1
  #   view.add_feed :always_include, 2
  # 
  #   expected = FeedItem.find(2, 4)
  #   actual = FeedItem.find_with_filters(:view => view, :order => 'feed_items.id ASC')
  #   assert_equal expected, actual
  # end
  
  # def test_find_with_tag_filter_and_always_include_feed_filter_should_only_return_items_with_that_tag_or_in_that_feed
  #   user = users(:quentin)
  #   tag = Tag(user, 'tag1')
  #   Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag)
  #   
  #   view = user.views.create!
  #   view.add_tag :include, tag
  #   view.add_feed :always_include, 2
  #   
  #   assert_equal FeedItem.find(2, 4), FeedItem.find_with_filters(:view => view, :order => 'feed_items.id ASC')
  # end
  
  # def test_find_with_tag_filter_and_multiple_always_include_feed_filter_should_only_return_items_with_that_tag_or_in_those_feeds
  #   user = users(:quentin)
  #   tag = Tag(user, 'tag1')
  #   Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag)
  #   
  #   view = user.views.create!
  #   view.add_tag :include, tag
  #   view.add_feed :always_include, 2
  #   view.add_feed :always_include, 1
  #   
  #   assert_equal FeedItem.find(1, 2, 3, 4), FeedItem.find_with_filters(:view => view, :order => 'feed_items.id ASC')
  # end
  
  def test_find_with_tag_filter_and_feed_filter_should_only_return_items_with_that_tag_or_in_that_feed
    user = users(:quentin)
    tag = Tag(user, 'tag1')
    Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag)
    Tagging.create(:user => user, :feed_item => FeedItem.find(4), :tag => tag)
  
    assert_equal FeedItem.find(2, 4), FeedItem.find_with_filters(:user => user, :feed_ids => "2", :tag_ids => tag.id.to_s)
  end
  
  def test_options_for_filters_creates_text_filter
    assert_match(/MATCH/, FeedItem.send(:options_for_filters, :user => users(:quentin), :text_filter => "text")[:joins])
  end
  
  def test_each_tagging_by_user
    user = users(:quentin)
    tag1 = Tag(user, 'tag1')
    tag2 = Tag(user, 'tag2')
    fi = FeedItem.find(1)
    tagging1 = Tagging.create(:user => user, :feed_item => fi, :tag => tag1)
    tagging2 = Tagging.create(:user => user, :feed_item => fi, :tag => tag2)
   
    assert_equal [[tag1, tagging1], [tag2, tagging2]], fi.taggings_by_user(user) 
  end
  
  def test_each_tagging_by_user_ignores_negative_taggings
    user = users(:quentin)
    fi = FeedItem.find(1)
    tagging1 = Tagging.create(:user => user, :feed_item => fi, :tag => Tag(user, 'tag1'), :strength => 1)
    tagging2 = Tagging.create(:user => user, :feed_item => fi, :tag => Tag(user, 'tag2'), :strength => 0)
    
    assert_equal [[Tag(user, 'tag1'), tagging1]], fi.taggings_by_user(user) 
  end
  
  def test_each_tagging_with_user_and_classifier_where_user_takes_priority
    user = users(:quentin)
    tag1 = Tag(user, 'tag1')
    tag2 = Tag(user, 'tag2')
    fi = FeedItem.find(1)
    u_tagging1 = Tagging.create(:user => user, :feed_item => fi, :tag => tag1)
    u_tagging2 = Tagging.create(:user => user, :feed_item => fi, :tag => tag2)
    c_tagging1 = Tagging.create(:user => user, :feed_item => fi, :tag => tag1, :classifier_tagging => true)
    c_tagging2 = Tagging.create(:user => user, :feed_item => fi, :tag => tag2, :classifier_tagging => true)
    
    expected = [[tag1, u_tagging1], [tag2, u_tagging2]]
    result = fi.taggings_by_user(user) 
    
    assert_equal expected.size, result.size
    assert_equal expected, result
  end
  
  def test_each_tagging_by_user_and_classifier_where_classifier_tags_float_up
    user = users(:quentin)
    tag1 = Tag(user, 'tag1')
    tag2 = Tag(user, 'tag2')
    fi = FeedItem.find(1)
    
    u_tagging1 = Tagging.create(:user => user, :feed_item => fi, :tag => tag1)
    c_tagging1 = Tagging.create(:user => user, :feed_item => fi, :tag => tag1, :classifier_tagging => true)
    c_tagging2 = Tagging.create(:user => user, :feed_item => fi, :tag => tag2, :classifier_tagging => true)
    
    expected = [[tag1, u_tagging1], [tag2, c_tagging2]]
    result = fi.taggings_by_user(user)
    
    assert_equal expected, result
  end
  
  def test_each_tagging_by_user_and_classifier_where_classifier_tags_float_up_except_it_is_too_weak
    user = users(:quentin)
    tag1 = Tag(user, 'tag1')
    tag2 = Tag(user, 'tag2')
    fi = FeedItem.find(1)
    
    u_tagging1 = Tagging.create(:user => user, :feed_item => fi, :tag => tag1)
    c_tagging1 = Tagging.create(:user => user, :feed_item => fi, :tag => tag1, :classifier_tagging => true)
    c_tagging2 = Tagging.create(:user => user, :feed_item => fi, :tag => tag2, :strength => 0.3, :classifier_tagging => true)
    
    expected = [[tag1, u_tagging1]]
    result = fi.taggings_by_user(user)
    
    assert_equal expected, result
  end
  
  def test_each_tagging_by_user_and_classifier_where_classifier_tag_is_overriden_by_negative_tagging
    user = users(:quentin)
    tag1 = Tag(user, 'tag1')
    tag2 = Tag(user, 'tag2')
    fi = FeedItem.find(1)
    
    u_tagging1 = Tagging.create(:user => user, :feed_item => fi, :tag => tag1, :strength => 0)
    c_tagging1 = Tagging.create(:user => user, :feed_item => fi, :tag => tag1, :strength => 0.99, :classifier_tagging => true)
    
    expected = []
    result = fi.taggings_by_user(user)
    
    assert_equal expected, result
  end
  
  def test_taggings_by_taggers_with_borderline_items
    user = users(:quentin)
    tag = Tag(user, 'tag')
    fi = FeedItem.find(1)
    
    c_tagging1 = Tagging.create(:user => user, :feed_item => fi, :tag => tag, :strength => 0.89, :classifier_tagging => true)
    
    expected = [[tag, c_tagging1]]
    result = fi.taggings_by_user(user)
    
    assert_equal expected.size, result.size
    assert_equal expected, result    
  end
  
  def test_all_taggings
    user = users(:quentin)
    tag1 = Tag(user, 'tag1')
    fi = FeedItem.find(1)

    u_tagging1 = Tagging.create(:user => user, :feed_item => fi, :tag => tag1, :strength => 0)
    c_tagging1 = Tagging.create(:user => user, :feed_item => fi, :tag => tag1, :strength => 0.99, :classifier_tagging => true)
  
    expected = [[tag1, [u_tagging1, c_tagging1]]]
    result = fi.taggings_by_user(user, :all_taggings => true)

    assert_equal expected.size, result.size
    assert_equal expected, result
  end
  
  def test_all_taggings_with_borderline_items
    user = users(:quentin)
    tag1 = Tag(user, 'tag1')
    fi = FeedItem.find(1)

    u_tagging1 = Tagging.create(:user => user, :feed_item => fi, :tag => tag1, :strength => 0)
    c_tagging1 = Tagging.create(:user => user, :feed_item => fi, :tag => tag1, :strength => 0.89, :classifier_tagging => true)
      
    expected = [[tag1, [u_tagging1, c_tagging1]]]
    result = fi.taggings_by_user(user, :all_taggings => true)

    assert_equal expected, result
  end

  def test_find_by_user_with_caching
    user = users(:quentin)
    fi = FeedItem.find(1)
    tagging_1 = Tagging.create(:user => user, :feed_item => fi, :tag => Tag(user, 'tag1'))
    tagging_2 = Tagging.create(:user => user, :feed_item => fi, :tag => Tag(user, 'tag2'))
    
    fi.taggings.cached_taggings.merge!({user => [tagging_1, tagging_2]})
    assert_equal([tagging_1, tagging_2], fi.taggings.find_by_user(user))
  end
  
  def test_find_by_user_with_caching_and_tag
    user = users(:quentin)
    fi = FeedItem.find(1)
    tagging_1 = Tagging.create(:user => user, :feed_item => fi, :tag => Tag(user, 'tag1'))
    tagging_2 = Tagging.create(:user => user, :feed_item => fi, :tag => Tag(user, 'tag2'))
    
    fi.taggings.cached_taggings.merge!({user => [tagging_1, tagging_2]})
    assert_equal([tagging_1], fi.taggings.find_by_user(user, Tag(user, 'tag1')))
  end
  
  def test_find_by_user_with_caching_and_multiple_users
    user = users(:quentin)
    u2 = users(:aaron)
    fi = FeedItem.find(1)
    tagging_1 = Tagging.create(:user => user, :feed_item => fi, :tag => Tag(user, 'tag1'))
    tagging_2 = Tagging.create(:user => user, :feed_item => fi, :tag => Tag(user, 'tag2'))
    tagging_3 = Tagging.create(:user => u2, :feed_item => fi, :tag => Tag(u2, 'tag1'))
    tagging_4 = Tagging.create(:user => u2, :feed_item => fi, :tag => Tag(u2, 'tag2'))
    
    fi.taggings.cached_taggings.merge!(user => [tagging_1, tagging_2], u2 => [tagging_3, tagging_4])
    assert_equal([tagging_1, tagging_2], fi.taggings.find_by_user(user))
    assert_equal([tagging_3, tagging_4], fi.taggings.find_by_user(u2))
  end
  
  def test_find_by_tagger_with_caching_and_missing_tagger
    user = users(:quentin)
    u2 = users(:aaron)
    fi = FeedItem.find(1)
    tagging_1 = Tagging.create(:user => user, :feed_item => fi, :tag => Tag(user, 'tag1'))
    tagging_2 = Tagging.create(:user => user, :feed_item => fi, :tag => Tag(user, 'tag2'))
    tagging_3 = Tagging.create(:user => u2, :feed_item => fi, :tag => Tag(u2, 'tag1'))
    tagging_4 = Tagging.create(:user => u2, :feed_item => fi, :tag => Tag(u2, 'tag2'))
    
    fi.taggings.cached_taggings.merge!({user => [tagging_1, tagging_2]})
    assert_equal([tagging_3, tagging_4], fi.taggings.find_by_user(u2))
  end

  def test_find_with_non_existent_include_tag_filter_should_ignore_the_nonexistent_tag
    user = users(:quentin)
    tag = Tag(user, 'tag1')
    Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag)
    
    assert_equal [FeedItem.find(2)], FeedItem.find_with_filters(:user => user, :tag_ids => "#{tag.id},#{tag.id + 1}")
  end

  def test_find_with_non_existent_tag_exclude_filter_should_ignore_the_nonexistent_tag
    user = users(:quentin)
    tag = Tag(user, 'tag1')
    Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag)
    
    user.tag_exclusions.create! :tag_id => tag.id
    user.tag_exclusions.create! :tag_id => tag.id + 1
    
    assert_equal FeedItem.find(1,3,4), FeedItem.find_with_filters(:user => user, :order => 'feed_items.id')
  end
  
  def test_including_both_subscribed_and_private_tags_returns_feed_items_from_either_tag
    quentin = users(:quentin)
    aaron = users(:aaron)
    
    f1 = FeedItem.find(1)
    f2 = FeedItem.find(2)
    
    tag1 = Tag(quentin, 'tag1')
    tag2 = Tag(aaron, 'tag2')
    tag2.public = true
    tag2.save!
    
    tagging_1 = Tagging.create(:user => quentin, :feed_item => f1, :tag => tag1)
    tagging_2 = Tagging.create(:user => aaron, :feed_item => f2, :tag => tag2)
    
    TagSubscription.create! :tag => tag2, :user => quentin
    
    assert_equal [f1, f2], FeedItem.find_with_filters(:user => quentin, :tag_ids => "#{tag1.id},#{tag2.id}", :order => 'feed_items.id')
  end
end
