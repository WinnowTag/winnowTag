# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
require File.dirname(__FILE__) + '/../test_helper'

class UpdateFiltersViewTest < Test::Unit::TestCase
  def test_changes_tag_inspect_mode
    @view = View.new
    assert !@view.tag_inspect_mode?
    
    # Should not change the mode
    @view.update_filters :mode => "garbage"
    assert !@view.tag_inspect_mode?
    
    # Should not change the mode
    @view.update_filters
    assert !@view.tag_inspect_mode?
    
    @view.update_filters :mode => "tag_inspect"
    assert @view.tag_inspect_mode?

    # Should not change the mode
    @view.update_filters :mode => "garbage"
    assert @view.tag_inspect_mode

    # Should not change the mode
    @view.update_filters
    assert @view.tag_inspect_mode

    @view.update_filters :mode => "normal"
    assert !@view.tag_inspect_mode?
  end

  def test_changes_show_untagged
    @view = View.new
    assert !@view.show_untagged?

    # Should not change show_untagged
    @view.update_filters
    assert !@view.show_untagged?

    @view.update_filters :show_untagged => "true"
    assert @view.show_untagged?

    # Should not change show_untagged
    @view.update_filters
    assert @view.show_untagged?

    @view.update_filters :show_untagged => "false"
    assert !@view.show_untagged?
  end

  def test_changes_text_filter
    @view = View.new
    assert_nil @view.text_filter
    
    @view.update_filters :text_filter => " "
    assert_nil @view.text_filter
    
    @view.update_filters :text_filter => "ruby"
    assert_equal "ruby", @view.text_filter
    
    @view.update_filters
    assert_equal "ruby", @view.text_filter
    
    @view.update_filters :text_filter => " "
    assert_nil @view.text_filter
  end
  
  def test_changes_feed_filter
    @view = View.new
    assert @view.feed_filter[:always_include].blank?
    assert @view.feed_filter[:include].blank?
    assert @view.feed_filter[:exclude].blank?
    
    @view.update_filters :feed_filter => "1"
    assert @view.feed_filter[:always_include].blank?
    assert_equal [1], @view.feed_filter[:include]
    assert @view.feed_filter[:exclude].blank?
    
    @view.update_filters :feed_filter => "1"
    assert @view.feed_filter[:always_include].blank?
    assert_equal [1], @view.feed_filter[:include]
    assert @view.feed_filter[:exclude].blank?
    
    @view.update_filters :feed_filter => "2"
    assert @view.feed_filter[:always_include].blank?
    assert_equal [1, 2], @view.feed_filter[:include]
    assert @view.feed_filter[:exclude].blank?
    
    @view.add_feed :always_include, 3
    @view.add_feed :exclude, 4
    assert !@view.feed_filter[:always_include].blank?
    assert !@view.feed_filter[:include].blank?
    assert !@view.feed_filter[:exclude].blank?
    
    @view.update_filters :feed_filter => "all"
    assert @view.feed_filter[:always_include].blank?
    assert @view.feed_filter[:include].blank?
    assert @view.feed_filter[:exclude].blank?
  end
  
  def test_changes_tag_filter
    @view = View.new
    assert @view.tag_filter[:include].blank?
    assert @view.tag_filter[:exclude].blank?
    
    @view.update_filters :tag_filter => "1"
    assert_equal [1], @view.tag_filter[:include]
    assert @view.tag_filter[:exclude].blank?
    
    @view.update_filters :tag_filter => "1"
    assert_equal [1], @view.tag_filter[:include]
    assert @view.tag_filter[:exclude].blank?
    
    @view.update_filters :tag_filter => "2"
    assert_equal [1, 2], @view.tag_filter[:include]
    assert @view.tag_filter[:exclude].blank?
    
    @view.add_tag :exclude, 3
    assert !@view.tag_filter[:include].blank?
    assert !@view.tag_filter[:exclude].blank?
    
    @view.update_filters :tag_filter => "all"
    assert @view.tag_filter[:include].blank?
    assert @view.tag_filter[:exclude].blank?
  end
end

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
    @tag = Tag(@user, 'tag')
    @user.taggings.create(:tag => @tag, :feed_item => FeedItem.find(1))
    @view = View.new :user => @user
  end
  
  def test_add_tag_to_include_list_when_list_is_empty
    assert @view.tag_filter[:include].empty?
    
    @view.add_tag :include, @tag
    assert_equal 1, @view.tag_filter[:include].size    
    assert @view.tag_filter[:include].include?(@tag.id)
  end

  def test_add_tag_to_include_list_when_list_is_not_empty
    @tag2 = Tag(@user, 'tag2')
    @user.taggings.create(:tag => @tag2, :feed_item => FeedItem.find(1))

    @view.add_tag :include, @tag2
    assert_equal 1, @view.tag_filter[:include].size
        
    @view.add_tag :include, @tag
    assert_equal 2, @view.tag_filter[:include].size
    assert @view.tag_filter[:include].include?(@tag.id)
    assert @view.tag_filter[:include].include?(@tag2.id)
  end
  
  def test_add_tag_to_include_when_tag_is_already_in_exclude
    @view.add_tag :exclude, @tag
    assert_equal 1, @view.tag_filter[:exclude].size
    
    @view.add_tag :include, @tag
    assert_equal 1, @view.tag_filter[:include].size
    assert @view.tag_filter[:include].include?(@tag.id)
    assert @view.tag_filter[:exclude].empty?
  end
  
  def test_add_tag_to_include_when_tag_is_already_in_include
    @view.add_tag :include, @tag
    assert_equal 1, @view.tag_filter[:include].size
    assert @view.tag_filter[:include].include?(@tag.id)
    
    @view.add_tag :include, @tag
    assert_equal 1, @view.tag_filter[:include].size
    assert @view.tag_filter[:include].include?(@tag.id)
  end
  
  def test_remove_tag_from_include
    @view.add_tag :include, @tag
    assert_equal 1, @view.tag_filter[:include].size
    assert @view.tag_filter[:include].include?(@tag.id)
    
    @view.remove_tag @tag
    assert @view.tag_filter[:include].empty?
  end
  
  def test_remove_tag_from_exclude
    @view.add_tag :exclude, @tag
    assert_equal 1, @view.tag_filter[:exclude].size
    assert @view.tag_filter[:exclude].include?(@tag.id)
    
    @view.remove_tag @tag
    assert @view.tag_filter[:exclude].empty?
  end
  
  def test_dup
    original_view = View.new :user => users(:quentin), :text_filter => "ruby", :tag_inspect_mode => true, :show_untagged => true
    original_view.add_tag :include, Tag(users(:quentin), 'demo')
    original_view.add_feed :include, 2
        
    dup_view = original_view.dup
    
    assert_equal users(:quentin), dup_view.user
    assert_equal({ :include => [Tag(users(:quentin), 'demo').id], :exclude => [] }, dup_view.tag_filter)
    assert_equal({ :always_include => [], :include => [2], :exclude => [] }, dup_view.feed_filter)
    assert_equal "ruby", dup_view.text_filter
    assert_equal true, dup_view.tag_inspect_mode?
    assert_equal true, dup_view.show_untagged?
  end
end