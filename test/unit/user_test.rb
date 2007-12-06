# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'
Tag

class UserTest < Test::Unit::TestCase  
  fixtures :users, :feed_items
  
  def test_has_many_views
    assert_association User, :has_many, :views
  end
  
  def test_has_many_tag_subscriptions
    assert_association User, :has_many, :tag_subscriptions
  end

  def test_should_be_owner_of_self
    u = create_user
    assert u.has_role?('owner', u)
  end
  
  def test_should_create_user
    assert_difference User, :count do
      user = create_user
      assert !user.new_record?, "#{user.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_login
    assert_no_difference User, :count do
      u = create_user(:login => nil)
      assert u.errors.on(:login)
    end
  end

  def test_should_require_password
    assert_no_difference User, :count do
      u = create_user(:password => nil)
      assert u.errors.on(:password)
    end
  end

  def test_should_require_email
    assert_no_difference User, :count do
      u = create_user(:email => nil)
      assert u.errors.on(:email)
    end
  end

  def test_should_reset_password
    users(:quentin).update_attributes(:password => 'new password', :password_confirmation => 'new password')
    assert_equal users(:quentin), User.authenticate('quentin', 'new password')
  end

  def test_should_not_rehash_password
    users(:quentin).update_attributes(:login => 'quentin2')
    assert_equal users(:quentin), User.authenticate('quentin2', 'test')
  end

  def test_should_authenticate_user
    assert_equal users(:quentin), User.authenticate('quentin', 'test')
  end

  def test_should_set_remember_token
    users(:quentin).remember_me
    assert_not_nil users(:quentin).remember_token
    assert_not_nil users(:quentin).remember_token_expires_at
  end

  def test_should_unset_remember_token
    users(:quentin).remember_me
    assert_not_nil users(:quentin).remember_token
    users(:quentin).forget_me
    assert_nil users(:quentin).remember_token
  end
   
  def test_tz_returns_time_zone_object
    user = create_user
    user.time_zone = 'Australia/Adelaide'
    assert_kind_of(TZInfo::Timezone, user.tz)
  end
  
  def test_tz_returns_utc_as_default
    user = create_user
    assert_equal(TZInfo::Timezone.get('UTC'), user.tz)
  end
  
  def test_create_user_with_timezone
    user = create_user(:tz => TZInfo::Timezone.get('Australia/Adelaide'))
    assert_equal(TZInfo::Timezone.get('Australia/Adelaide'), user.tz)
  end
  
  def test_timezone_should_not_be_nil
    assert_invalid create_user(:time_zone => nil)
  end
  
  def test_timezone_must_be_valid
    u = create_user
    u.time_zone = 'INVALID'
    assert_invalid u
  end
  
  def test_has_read_item_when_unread_item_entry_exists
    u = User.find(1)
    f = FeedItem.find(1)
    u.unread_items.create(:feed_item => f)
    assert !u.has_read_item?(f)
  end
  
  def test_is_item_unread_when_it_doesnt_exist
    u = User.find(1)
    f = FeedItem.find(2)
    assert u.has_read_item?(f)
  end
  
  def test_tagging_statistics
    u = users(:quentin)
    pw = Tag(u, 'peerworks')
    tag = Tag(u, 'tag')

    assert_equal 0, u.tagging_percentage
    assert_nil u.last_tagging_on
    assert_equal 0, u.average_taggings_per_item
    assert_equal 0, u.number_of_tagged_items

    assert Tagging.create(:user => u, :feed_item => FeedItem.find(1), :tag => pw)
    assert last = Tagging.create(:user => u, :feed_item => FeedItem.find(2), :tag => pw)

    assert_equal 50, u.tagging_percentage
    assert_equal last.created_on.to_s, u.last_tagging_on.to_s
    assert_equal 1, u.average_taggings_per_item
    assert_equal 2, u.number_of_tagged_items

    Tagging.create(:user => u, :feed_item => FeedItem.find(1), :tag => tag)
    last = Tagging.create(:user => u, :feed_item => FeedItem.find(2), :tag => tag)

    assert_equal 50, u.tagging_percentage
    assert_equal last.created_on.to_s, u.last_tagging_on.to_s
    assert_equal 2, u.average_taggings_per_item
    assert_equal 2, u.number_of_tagged_items

    Tagging.create(:user => u, :feed_item => FeedItem.find(3), :tag => pw)
    last = Tagging.create(:user => u, :feed_item => FeedItem.find(4), :tag => pw)

    assert_equal 100, u.tagging_percentage
    assert_equal last.created_on.to_s, u.last_tagging_on.to_s
    assert_equal 1.5, u.average_taggings_per_item
    assert_equal 4, u.number_of_tagged_items

    User.find_by_login('quentin').taggings.clear
    assert_equal 0, u.tagging_percentage
    assert_nil u.last_tagging_on
    assert_equal 0, u.average_taggings_per_item
    assert_equal 0, u.number_of_tagged_items
  end
  
  def test_knows_that_given_user_is_not_subscribed
    current_user = users(:quentin)
    tag = Tag(current_user, 'hockey')
    TagSubscription.delete_all
    
    assert !current_user.subscribed?(tag)
  end
  
  def test_knows_that_given_user_is_subscribed
    current_user = users(:quentin)
    tag = Tag(current_user, 'hockey')
    TagSubscription.create! :tag_id => tag.id, :user_id => current_user
    
    assert current_user.subscribed?(tag)
  end

protected
  def create_user(options = {})
    User.create({ :login => 'quire', 
                  :email => 'quire@example.com', 
                  :password => 'quire', 
                  :firstname => 'Qu', 
                  :lastname => 'Ire',
                  :password_confirmation => 'quire' }.merge(options))
  end
end
