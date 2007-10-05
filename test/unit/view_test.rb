# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
require File.dirname(__FILE__) + '/../test_helper'

class FeedViewTest < Test::Unit::TestCase
  def test_add_feed_to_include_list_when_list_is_empty
    view = View.new
    assert view.feed_filter[:include].empty?
    
    view.add_feed :include, 1
    assert_equal 1, view.feed_filter[:include].size
    assert view.feed_filter[:include].include?(1)
  end

  def test_add_feed_to_include_list_when_list_is_not_empty
    view = View.new
    view.add_feed :include, 2
    assert_equal 1, view.feed_filter[:include].size
    
    view.add_feed :include, 1
    assert_equal 2, view.feed_filter[:include].size
    assert view.feed_filter[:include].include?(1)
    assert view.feed_filter[:include].include?(2)
  end
  
  def test_add_feed_to_include_when_feed_is_already_in_exclude
    view = View.new
    view.add_feed :exclude, 1
    assert_equal 1, view.feed_filter[:exclude].size
    
    view.add_feed :include, 1
    assert_equal 1, view.feed_filter[:include].size
    assert view.feed_filter[:include].include?(1)
    assert view.feed_filter[:exclude].empty?
  end
  
  def test_add_feed_to_include_when_feed_is_already_in_include
    view = View.new
    view.add_feed :include, 1
    assert_equal 1, view.feed_filter[:include].size
    assert view.feed_filter[:include].include?(1)
    
    view.add_feed :include, 1
    assert_equal 1, view.feed_filter[:include].size
    assert view.feed_filter[:include].include?(1)
  end
  
  def test_remove_feed_from_include
    view = View.new
    view.add_feed :include, 1
    assert_equal 1, view.feed_filter[:include].size
    assert view.feed_filter[:include].include?(1)
    
    view.remove_feed 1
    assert view.feed_filter[:include].empty?
  end
  
  def test_remove_feed_from_exclude
    view = View.new
    view.add_feed :exclude, 1
    assert_equal 1, view.feed_filter[:exclude].size
    assert view.feed_filter[:exclude].include?(1)
    
    view.remove_feed 1
    assert view.feed_filter[:exclude].empty?
  end
end

class TagViewTest < Test::Unit::TestCase
  fixtures :users, :feed_items
  
  def setup
    @user = users(:quentin)
    @tag = Tag('tag')
    @user.taggings.create(:tag => @tag, :taggable => FeedItem.find(1))
    @view = View.new :user => @user
  end
  
  def test_add_tag_to_include_list_when_list_is_empty
    assert @view.tag_filter[:include].empty?
    
    @view.add_tag :include, @tag
    assert_equal 1, @view.tag_filter[:include].size    
    assert @view.tag_filter[:include].include?(@tag.id.to_s)
  end

  def test_add_tag_to_include_list_when_list_is_not_empty
    @tag2 = Tag('tag2')
    @user.taggings.create(:tag => @tag2, :taggable => FeedItem.find(1))

    @view.add_tag :include, @tag2
    assert_equal 1, @view.tag_filter[:include].size
        
    @view.add_tag :include, @tag
    assert_equal 2, @view.tag_filter[:include].size
    assert @view.tag_filter[:include].include?(@tag.id.to_s)
    assert @view.tag_filter[:include].include?(@tag2.id.to_s)
  end
  
  def test_add_tag_to_include_when_tag_is_already_in_exclude
    @view.add_tag :exclude, @tag
    assert_equal 1, @view.tag_filter[:exclude].size
    
    @view.add_tag :include, @tag
    assert_equal 1, @view.tag_filter[:include].size
    assert @view.tag_filter[:include].include?(@tag.id.to_s)
    assert @view.tag_filter[:exclude].empty?
  end
  
  def test_add_tag_to_include_when_tag_is_already_in_include
    @view.add_tag :include, @tag
    assert_equal 1, @view.tag_filter[:include].size
    assert @view.tag_filter[:include].include?(@tag.id.to_s)
    
    @view.add_tag :include, @tag
    assert_equal 1, @view.tag_filter[:include].size
    assert @view.tag_filter[:include].include?(@tag.id.to_s)
  end
  
  def test_remove_tag_from_include
    @view.add_tag :include, @tag
    assert_equal 1, @view.tag_filter[:include].size
    assert @view.tag_filter[:include].include?(@tag.id.to_s)
    
    @view.remove_tag @tag
    assert @view.tag_filter[:include].empty?
  end
  
  def test_remove_tag_from_exclude
    @view.add_tag :exclude, @tag
    assert_equal 1, @view.tag_filter[:exclude].size
    assert @view.tag_filter[:exclude].include?(@tag.id.to_s)
    
    @view.remove_tag @tag
    assert @view.tag_filter[:exclude].empty?
  end
end