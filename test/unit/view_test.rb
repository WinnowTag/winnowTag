# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
require File.dirname(__FILE__) + '/../test_helper'
Tag

class UpdateFiltersViewTest < Test::Unit::TestCase
  fixtures :feeds, :users
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
    @feed1 = Feed.create! :url => "http://one.example.com"
    @feed2 = Feed.create! :url => "http://two.example.com"
    @feed3 = Feed.create! :url => "http://three.example.com"
    @feed4 = Feed.create! :url => "http://four.example.com"
    @user = User.create! :firstname => "John", :lastname => "Doe", :email => "john.doe@example.com",
                         :login => "john.doe", :password => "password", :password_confirmation => "password"
    @view = @user.views.create!

    assert @view.feed_filters.empty?
    
    @view.update_filters :feed_filter => @feed1
    assert @view.feed_filters.always_include.empty?
    assert_equal 1, @view.feed_filters.include.size
    assert @view.feed_filters.includes?(:include, @feed1)
    assert @view.feed_filters.exclude.empty?
    
    @view.update_filters :feed_filter => @feed1
    assert @view.feed_filters.always_include.empty?
    assert_equal 1, @view.feed_filters.include.size
    assert @view.feed_filters.includes?(:include, @feed1)
    assert @view.feed_filters.exclude.empty?
    
    @view.update_filters :feed_filter => @feed2
    assert @view.feed_filters.always_include.empty?
    assert_equal 2, @view.feed_filters.include.size
    assert @view.feed_filters.includes?(:include, @feed1)
    assert @view.feed_filters.includes?(:include, @feed2)
    assert @view.feed_filters.exclude.empty?
    
    @view.add_feed :always_include, @feed3
    @view.add_feed :exclude, @feed4
    assert !@view.feed_filters.always_include.empty?
    assert !@view.feed_filters.include.empty?
    assert !@view.feed_filters.exclude.empty?
    
    @view.update_filters :feed_filter => "all"
    assert @view.feed_filters.always_include.empty?
    assert @view.feed_filters.include.empty?
    assert @view.feed_filters.exclude.empty?
  end
  
  def test_changes_tag_filter
    @user = User.create! :firstname => "John", :lastname => "Doe", :email => "john.doe@example.com",
                         :login => "john.doe", :password => "password", :password_confirmation => "password"
    @tag1 = Tag(@user, 'tag1')
    @tag2 = Tag(@user, 'tag2')
    @tag3 = Tag(@user, 'tag3')

    @view = @user.views.create!

    assert @view.tag_filters.empty?
    
    @view.update_filters :tag_filter => @tag1
    assert_equal 1, @view.tag_filters.include.size
    assert @view.tag_filters.includes?(:include, @tag1)
    assert @view.tag_filters.exclude.blank?
    
    @view.update_filters :tag_filter => @tag1
    assert_equal 1, @view.tag_filters.include.size
    assert @view.tag_filters.includes?(:include, @tag1)
    assert @view.tag_filters.exclude.blank?
    
    @view.update_filters :tag_filter => @tag2
    assert_equal 2, @view.tag_filters.include.size
    assert @view.tag_filters.includes?(:include, @tag1)
    assert @view.tag_filters.includes?(:include, @tag2)
    assert @view.tag_filters.exclude.blank?
    
    @view.add_tag :exclude, @tag3
    assert !@view.tag_filters.include.blank?
    assert !@view.tag_filters.exclude.blank?
    
    @view.update_filters :tag_filter => "all"
    assert @view.tag_filters.include.blank?
    assert @view.tag_filters.exclude.blank?
  end
end

class FeedViewTest < Test::Unit::TestCase
  fixtures :feeds, :users
  
  def setup
    @feed1 = Feed.create! :url => "http://one.example.com"
    @feed2 = Feed.create! :url => "http://two.example.com"
    @user = User.create! :firstname => "John", :lastname => "Doe", :email => "john.doe@example.com",
                         :login => "john.doe", :password => "password", :password_confirmation => "password"
    @view = @user.views.create!

    assert @view.feed_filters.empty?
  end
  
  def test_add_feed_to_include_list_when_list_is_empty
    @view.add_feed :include, @feed1
    
    assert_equal 1, @view.feed_filters.size
    assert_equal 1, @view.feed_filters.include.size
    assert @view.feed_filters.includes?(:include, @feed1)
  end

  def test_add_feed_to_include_list_when_list_is_not_empty
    @view.add_feed :include, @feed1
    @view.add_feed :include, @feed2

    assert_equal 2, @view.feed_filters.size
    assert_equal 2, @view.feed_filters.include.size
    assert @view.feed_filters.includes?(:include, @feed1)
    assert @view.feed_filters.includes?(:include, @feed2)
  end
  
  def test_add_feed_to_include_when_feed_is_already_in_exclude
    @view.add_feed :exclude, @feed1
    @view.add_feed :include, @feed1

    assert_equal 1, @view.feed_filters.size
    assert_equal 0, @view.feed_filters.exclude.size
    assert_equal 1, @view.feed_filters.include.size
    assert @view.feed_filters.includes?(:include, @feed1)
  end
  
  def test_add_feed_to_include_when_feed_is_already_in_include
    @view.add_feed :include, @feed1
    @view.add_feed :include, @feed1

    assert_equal 1, @view.feed_filters.size
    assert_equal 1, @view.feed_filters.include.size
    assert @view.feed_filters.includes?(:include, @feed1)
  end
  
  def test_remove_feed_from_include
    @view.add_feed :include, @feed1

    assert_equal 1, @view.feed_filters.size
    assert_equal 1, @view.feed_filters.include.size
    assert @view.feed_filters.includes?(:include, @feed1)
    
    @view.remove_feed @feed1
    assert @view.feed_filters.empty?
    assert @view.feed_filters.include.empty?
  end
  
  def test_remove_feed_from_exclude
    @view.add_feed :exclude, @feed1

    assert_equal 1, @view.feed_filters.size
    assert_equal 1, @view.feed_filters.exclude.size
    assert @view.feed_filters.includes?(:exclude, @feed1)
    
    @view.remove_feed @feed1
    assert @view.feed_filters.empty?
    assert @view.feed_filters.exclude.empty?
  end
end

class TagViewTest < Test::Unit::TestCase
  fixtures :users, :feed_items
    
  def setup
    @user = users(:quentin)
    @tag = Tag(@user, 'tag')
    @user.taggings.create(:tag => @tag, :feed_item => FeedItem.find(1))
    @view = @user.views.create!
  end
  
  def test_add_tag_to_include_list_when_list_is_empty
    assert @view.tag_filters.include.empty?
    
    @view.add_tag :include, @tag
    assert_equal 1, @view.tag_filters.include.size    
    assert @view.tag_filters.includes?(:include, @tag)
  end

  def test_add_tag_to_include_list_when_list_is_not_empty
    @tag2 = Tag(@user, 'tag2')
    @user.taggings.create(:tag => @tag2, :feed_item => FeedItem.find(1))

    @view.add_tag :include, @tag2
    assert_equal 1, @view.tag_filters.include.size
        
    @view.add_tag :include, @tag
    assert_equal 2, @view.tag_filters.include.size
    assert @view.tag_filters.includes?(:include, @tag)
    assert @view.tag_filters.includes?(:include, @tag2)
  end
  
  def test_add_tag_to_include_when_tag_is_already_in_exclude
    @view.add_tag :exclude, @tag
    assert_equal 1, @view.tag_filters.exclude.size
    
    @view.add_tag :include, @tag
    assert_equal 1, @view.tag_filters.include.size
    assert @view.tag_filters.includes?(:include, @tag)
    assert @view.tag_filters.exclude.empty?
  end
  
  def test_add_tag_to_include_when_tag_is_already_in_include
    @view.add_tag :include, @tag
    assert_equal 1, @view.tag_filters.include.size
    assert @view.tag_filters.includes?(:include, @tag)
    
    @view.add_tag :include, @tag
    assert_equal 1, @view.tag_filters.include.size
    assert @view.tag_filters.includes?(:include, @tag)
  end
  
  def test_remove_tag_from_include
    @view.add_tag :include, @tag
    assert_equal 1, @view.tag_filters.include.size
    assert @view.tag_filters.includes?(:include, @tag)
    
    @view.remove_tag @tag
    assert @view.tag_filters.include.empty?
  end
  
  def test_remove_tag_from_exclude
    @view.add_tag :exclude, @tag
    assert_equal 1, @view.tag_filters.exclude.size
    assert @view.tag_filters.includes?(:exclude, @tag)
    
    @view.remove_tag @tag
    assert @view.tag_filters.exclude.empty?
  end
  
  def test_dup
    original_view = View.create! :user => users(:quentin), :text_filter => "ruby", :tag_inspect_mode => true, :show_untagged => true
    @tag = Tag(users(:quentin), 'demo')
    original_view.add_tag :include, @tag
    @feed = Feed.create! :url => "http://example.com"
    original_view.add_feed :include, @feed
        
    dup_view = original_view.dup!
    
    assert_equal users(:quentin), dup_view.user
    assert_equal 1, dup_view.tag_filters.size
    assert dup_view.tag_filters.includes?(:include, @tag)
    assert_equal 1, dup_view.feed_filters.size
    assert dup_view.feed_filters.includes?(:include, @feed)
    assert_equal "ruby", dup_view.text_filter
    assert_equal true, dup_view.tag_inspect_mode?
    assert_equal true, dup_view.show_untagged?
  end
end