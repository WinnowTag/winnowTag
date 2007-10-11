# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'

class FeedItemTest < Test::Unit::TestCase
  fixtures :feed_items, :users, :roles, :roles_users, :feed_item_tokens_containers, :tag_publications, :bayes_classifiers
  
  def test_tokens_calls_create
    tokens = {'a' => 1, 'b' => 2, 'c' => 3}
    fi = FeedItem.new
    fi.token_containers.expects(:create).with(:tokens_with_counts => tokens, :tokenizer_version => 1)
    fi.tokens_with_counts(1) do |feed_item|
      assert_equal fi, feed_item
      tokens
    end
  end
  
  def test_tokens_retrieves_from_db
    tokens = {'a' => 1, 'b' => 2, 'c' => 3}
    fi = FeedItem.find(1)
    fi.tokens_with_counts(1) do |feed_item|
      tokens
    end
    # do it again to make sure they were saved
    assert_equal tokens, fi.tokens_with_counts(1)
  end
  
  def test_tokens_when_no_tokens_exist
    fi = FeedItem.find(1)
    assert_nil(fi.tokens(1))
  end
  
  def test_tokens_when_tokens_exist_in_db
    fi = FeedItem.find(1)
    assert_equal(feed_item_tokens_containers(:tokens_for_first).tokens, fi.tokens(0))
  end
  
  def test_tokens_when_selected_with_item
    expected = feed_item_tokens_containers(:tokens_for_first).tokens
    FeedItemTokensContainer.expects(:find).never
    fi = FeedItem.find(:first, :select => 'feed_items.*, feed_item_tokens_containers.tokens as tokens',
                              :joins => 'inner join feed_item_tokens_containers on feed_items.id = feed_item_tokens_containers.feed_item_id')
    assert_equal(expected, fi.tokens(0))
  end
  
  def test_getting_content_when_content_returns_empty_content
    feed_item = FeedItem.new    
    assert_nil feed_item.content.title
    assert_nil feed_item.content.link
  end
  
  # Tests for the find_with_filters method
  def test_find_with_no_filters_should_return_everything
    view = View.new :user => users(:quentin)

    feed_items = FeedItem.find_with_filters(:view => view, :order => 'feed_items.id ASC')
    assert_equal FeedItem.find(:all), feed_items
  end
  
  def test_find_with_feed_filters_should_return_only_items_from_the_included_feed
    view = View.new :user => users(:quentin)
    view.add_feed :include, 1

    feed_items = FeedItem.find_with_filters(:view => view, :order => 'feed_items.id ASC')
    assert_equal [FeedItem.find(1), FeedItem.find(2), FeedItem.find(3)], feed_items
  end
  
  def test_find_with_feed_filters_should_return_only_items_from_multiple_included_feeds
    view = View.new :user => users(:quentin)
    view.add_feed :include, 1
    view.add_feed :include, 2

    feed_items = FeedItem.find_with_filters(:view => view, :order => 'feed_items.id ASC')
    assert_equal [FeedItem.find(1), FeedItem.find(2), FeedItem.find(3), FeedItem.find(4)], feed_items
  end
  
  def test_find_with_feed_filters_should_return_only_items_not_excluded_from_the_feed
    view = View.new :user => users(:quentin)
    view.add_feed :exclude, 1

    feed_items = FeedItem.find_with_filters(:view => view, :order => 'feed_items.id ASC')
    assert_equal [FeedItem.find(4)], feed_items
  end
  
  def test_find_with_feed_filters_should_return_none_when_all_feeds_are_excluded
    view = View.new :user => users(:quentin)
    view.add_feed :exclude, 1
    view.add_feed :exclude, 2

    feed_items = FeedItem.find_with_filters(:view => view, :order => 'feed_items.id ASC')
    assert_equal [], feed_items
  end
  
  def test_find_tagged_with_feed_filter
    Tagging.create(:tagger => users(:quentin), :taggable => FeedItem.find(1), :tag => Tag('tag1'))
    Tagging.create(:tagger => users(:quentin), :taggable => FeedItem.find(4), :tag => Tag('tag1'))
    
    
    view = View.new :user => users(:quentin)
    view.add_feed :include, 1
    view.tagged_state = "tagged"
    
    feed_items = FeedItem.find_with_filters(:view => view, :order => 'feed_items.id ASC')
    assert_equal [FeedItem.find(1)], feed_items
  end
  
  def test_find_with_tag_filter_should_only_return_items_with_that_tag
    user = users(:quentin)
    tag = Tag.find_or_create_by_name('tag1')
    Tagging.create(:tagger => user, :taggable => FeedItem.find(2), :tag => tag)
    
    view = View.new :user => user
    view.add_tag :include, tag
    
    assert_equal [FeedItem.find(2)], FeedItem.find_with_filters(:view => view)
  end
  
  def test_find_with_multiple_tag_filters_should_only_return_items_with_those_tags
    user = users(:quentin)
    tag = Tag.find_or_create_by_name('tag1')
    tag2 = Tag.find_or_create_by_name('tag2')
    Tagging.create(:tagger => user, :taggable => FeedItem.find(2), :tag => tag)
    Tagging.create(:tagger => user, :taggable => FeedItem.find(3), :tag => tag2)
    
    view = View.new :user => user
    view.add_tag :include, tag
    view.add_tag :include, tag2
    
    assert_equal [FeedItem.find(2), FeedItem.find(3)], FeedItem.find_with_filters(:view => view, :order => 'feed_items.id ASC')
  end
  
  def test_find_with_tag_filter_and_always_include_feed_filter_should_only_return_items_with_that_tag_or_in_that_feed
    user = users(:quentin)
    tag = Tag.find_or_create_by_name('tag1')
    Tagging.create(:tagger => user, :taggable => FeedItem.find(2), :tag => tag)
    
    view = View.new :user => user
    view.add_tag :include, tag
    view.add_feed :always_include, 2
    
    assert_equal [FeedItem.find(2), FeedItem.find(4)], FeedItem.find_with_filters(:view => view, :order => 'feed_items.id ASC')
  end
  
  def test_find_with_tag_filter_and_multiple_always_include_feed_filter_should_only_return_items_with_that_tag_or_in_those_feeds
    user = users(:quentin)
    tag = Tag.find_or_create_by_name('tag1')
    Tagging.create(:tagger => user, :taggable => FeedItem.find(2), :tag => tag)
    
    view = View.new :user => user
    view.add_tag :include, tag
    view.add_feed :always_include, 2
    view.add_feed :always_include, 1
    
    assert_equal [FeedItem.find(1), FeedItem.find(2), FeedItem.find(3), FeedItem.find(4)], FeedItem.find_with_filters(:view => view, :order => 'feed_items.id ASC')
  end
  
  def test_find_with_tag_filter_excludes_negative_taggings
    user = users(:quentin)
    tag = Tag.find_or_create_by_name('tag1')
    Tagging.create(:tagger => user, :taggable => FeedItem.find(2), :tag => tag)
    Tagging.create(:tagger => user, :taggable => FeedItem.find(3), :tag => tag, :strength => 0)

    view = View.new :user => user
    view.add_tag :include, tag

    assert_equal [FeedItem.find(2)], FeedItem.find_with_filters(:view => view)
  end
  
  def test_find_with_tag_filter_negative_taggings_exclude_positive_classifier_taggings
    user = users(:quentin)
    tag = Tag.find_or_create_by_name('tag1')
    Tagging.create(:tagger => user, :taggable => FeedItem.find(2), :tag => tag)
    Tagging.create(:tagger => user.classifier, :taggable => FeedItem.find(3), :tag => tag)
    Tagging.create(:tagger => user, :taggable => FeedItem.find(3), :tag => tag, :strength => 0)

    view = View.new :user => user
    view.add_tag :include, tag

    assert_equal [FeedItem.find(2)], FeedItem.find_with_filters(:view => view)
  end
  
  def test_find_with_tag_filter_should_ignore_other_users_tags
    user = users(:quentin)
    tag = Tag.find_or_create_by_name('tag1')
    Tagging.create(:tagger => user, :taggable => FeedItem.find(2), :tag => tag)
    Tagging.create(:tagger => users(:aaron), :taggable => FeedItem.find(3), :tag => tag)

    view = View.new :user => user
    view.add_tag :include, tag

    assert_equal [FeedItem.find(2)], FeedItem.find_with_filters(:view => view)
  end
  
  def test_find_with_tag_filter_and_feed_filter_should_only_return_items_with_that_tag_in_that_feed
    user = users(:quentin)
    tag = Tag.find_or_create_by_name('tag1')
    Tagging.create(:tagger => user, :taggable => FeedItem.find(2), :tag => tag)
    Tagging.create(:tagger => user, :taggable => FeedItem.find(4), :tag => tag)

    view = View.new :user => user
    view.add_tag :include, tag
    view.add_feed :include, 1

    assert_equal [FeedItem.find(2)], FeedItem.find_with_filters(:view => view)
  end
  
  def test_find_with_tag_filter_should_include_classifier_tags
    user = users(:quentin)
    tag = Tag.find_or_create_by_name('tag1')
    Tagging.create(:tagger => user, :taggable => FeedItem.find(2), :tag => tag)
    Tagging.create(:tagger => user.classifier, :taggable => FeedItem.find(3), :tag => tag)

    view = View.new :user => user
    view.add_tag :include, tag

    assert_equal [FeedItem.find(2), FeedItem.find(3)], FeedItem.find_with_filters(:view => view, :order => 'feed_items.id ASC')
  end
  
  def test_find_with_tagged_filter_should_only_return_tagged_items
    user = users(:quentin)
    tag1 = Tag.find_or_create_by_name('tag1')
    tag2 = Tag.find_or_create_by_name('tag2')
    Tagging.create(:tagger => user, :taggable => FeedItem.find(2), :tag => tag1)
    Tagging.create(:tagger => user, :taggable => FeedItem.find(3), :tag => tag2)
    
    view = View.new :user => user
    view.tagged_state = "tagged"
    
    expected = [FeedItem.find(2), FeedItem.find(3)]
    assert_equal expected, FeedItem.find_with_filters(:view => view, :order => 'feed_items.id ASC')
  end
  
  def test_find_with_untagged_filter_should_only_return_untagged_items
    user = users(:quentin)
    tag1 = Tag.find_or_create_by_name('tag1')
    tag2 = Tag.find_or_create_by_name('tag2')
    Tagging.create(:tagger => user, :taggable => FeedItem.find(2), :tag => tag1)
    Tagging.create(:tagger => user, :taggable => FeedItem.find(3), :tag => tag2)
    
    view = View.new :user => user
    view.tagged_state = "untagged"
    
    expected = [FeedItem.find(1), FeedItem.find(4)]
    assert_equal expected, FeedItem.find_with_filters(:view => view, :order => 'feed_items.id ASC')
  end
  
  def test_find_with_tagged_filter_should_include_classifier_tags
    user = users(:quentin)
    tag1 = Tag.find_or_create_by_name('tag1')
    tag2 = Tag.find_or_create_by_name('tag2')
    Tagging.create(:tagger => user, :taggable => FeedItem.find(2), :tag => tag1)
    Tagging.create(:tagger => user.classifier, :taggable => FeedItem.find(3), :tag => tag2)

    view = View.new :user => user
    view.tagged_state = "tagged"
    
    expected = [FeedItem.find(2), FeedItem.find(3)]
    assert_equal expected, FeedItem.find_with_filters(:view => view, :order => 'feed_items.id ASC')
  end
  
  def test_find_with_excluded_tag_should_return_items_not_tagged_with_that_tag
    user = users(:quentin)
    tag1 = Tag.find_or_create_by_name('tag1')
    tag2 = Tag.find_or_create_by_name('tag2')
    Tagging.create(:tagger => user, :taggable => FeedItem.find(2), :tag => tag1)
    Tagging.create(:tagger => user, :taggable => FeedItem.find(3), :tag => tag1)
    Tagging.create(:tagger => user, :taggable => FeedItem.find(3), :tag => tag2)

    view = View.new :user => user
    view.add_tag :exclude, Tag('tag1')
    
    expected = [FeedItem.find(1), FeedItem.find(4)]
    assert_equal expected, FeedItem.find_with_filters(:view => view, :order => 'feed_items.id ASC')
  end
  
  def test_find_with_included_and_excluded_tags_should_return_items_tagged_with_included_tag_and_not_the_excluded_tag
    user = users(:quentin)
    tag1 = Tag.find_or_create_by_name('tag1')
    tag2 = Tag.find_or_create_by_name('tag2')
    Tagging.create(:tagger => user, :taggable => FeedItem.find(2), :tag => tag1)
    Tagging.create(:tagger => user, :taggable => FeedItem.find(3), :tag => tag1)
    Tagging.create(:tagger => user, :taggable => FeedItem.find(3), :tag => tag2)

    view = View.new :user => user
    view.add_tag :include, Tag('tag1')
    view.add_tag :exclude, Tag('tag2')
    
    expected = [FeedItem.find(2)]
    assert_equal expected, FeedItem.find_with_filters(:view => view, :order => 'feed_items.id ASC')
  end
  
  def test_find_with_multiple_excluded_tags_should_return_items_not_tagged_with_those_tags
    user = users(:quentin)
    tag1 = Tag.find_or_create_by_name('tag1')
    tag2 = Tag.find_or_create_by_name('tag2')
    Tagging.create(:tagger => user, :taggable => FeedItem.find(2), :tag => tag1)
    Tagging.create(:tagger => user, :taggable => FeedItem.find(3), :tag => tag2)

    view = View.new :user => user
    view.add_tag :exclude, Tag('tag1')
    view.add_tag :exclude, Tag('tag2')
    
    expected = [FeedItem.find(1), FeedItem.find(4)]
    assert_equal expected, FeedItem.find_with_filters(:view => view, :order => 'feed_items.id ASC')
  end
  
  def test_find_includes_borderline_items
    user = users(:quentin)
    tag1 = Tag.find_or_create_by_name('tag1')
    tag2 = Tag.find_or_create_by_name('tag2')
    Tagging.create(:tagger => user, :taggable => FeedItem.find(2), :tag => tag1)
    Tagging.create(:tagger => user.classifier, :taggable => FeedItem.find(3), :tag => tag2)
    Tagging.create(:tagger => user.classifier, :taggable => FeedItem.find(4), :tag => tag2, :strength => 0.89)
    
    view = View.new :user => user
    view.tagged_state = "tagged"
    
    expected = [FeedItem.find(2), FeedItem.find(3), FeedItem.find(4)]
    assert_equal expected, FeedItem.find_with_filters(:view => view, :order => 'feed_items.id ASC')    
  end
  
  def test_find_with_negatives_includes_negativey_tagged_items
    user = users(:quentin)
    tag = Tag.find_or_create_by_name('tag')
    Tagging.create(:tagger => user, :taggable => FeedItem.find(2), :tag => tag)
    Tagging.create(:tagger => user, :taggable => FeedItem.find(4), :tag => tag, :strength => 0)
    
    view = View.new :user => user
    view.add_tag :include, tag
    
    expected = [FeedItem.find(2), FeedItem.find(4)]
    assert_equal(expected, FeedItem.find_with_filters(:view => view, :only_tagger => 'user', :include_negative => true, :order => 'feed_items.id asc'))
  end
  
  def test_find_with_tag_publication_tag_filter
    user = users(:quentin)
    tag_pub = TagPublication.find(1)
    tag_pub.taggings.create(:tag => tag_pub.tag, :taggable => FeedItem.find(1))
    
    view = View.new :user => user
    view.add_tag :include, tag_pub
     
    expected = [FeedItem.find(1)]
    assert_equal(expected, FeedItem.find_with_filters(:view => view))
  end
  
  def test_find_with_tag_publication_tag_filter_includes_publications_classifier_tags
    user = users(:quentin)
    tag_pub = TagPublication.find(1)
    tag_pub.classifier.taggings.create(:tag => tag_pub.tag, :taggable => FeedItem.find(1))
    
    view = View.new :user => user
    view.add_tag :include, tag_pub
    
    expected = [FeedItem.find(1)]
    assert_equal(expected, FeedItem.find_with_filters(:view => view))
  end

  def test_find_with_tag_publication_tag_filter_excludes_publications_classifier_tags_when_overriden_by_negative
    user = users(:quentin)
    tag_pub = TagPublication.find(1)
    tag_pub.taggings.create(:tag => tag_pub.tag, :taggable => FeedItem.find(1), :strength => 0)
    tag_pub.classifier.taggings.create(:tag => tag_pub.tag, :taggable => FeedItem.find(1))
     
    view = View.new :user => user
    view.add_tag :include, tag_pub
     
    expected = []
    assert_equal(expected, FeedItem.find_with_filters(:view => view))
  end
  
  def test_options_for_filters_creates_text_filter
    view = View.new
    view.text_filter = "text"
    assert_match(/MATCH/, FeedItem.send(:options_for_filters, :view => view)[:conditions])
  end
  
  def test_find_with_text_filter_works
    view = View.new
    view.text_filter = "text"
    
    assert_nothing_raised do
      FeedItem.find_with_filters(:view => view)
    end
  end
end
