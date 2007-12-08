# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'

class RemoteProtectedItemsTest < Test::Unit::TestCase  
  fixtures :users
  def setup
    Protector.create(:protector_id => 1)
    ActiveResource::HttpMock.respond_to do |http|
      http.post "/protectors/1/protected_items.xml", {}, nil, 201, 'Location' => '/protectors/1/protected_items/2'
      http.delete "/protectors/1/protected_items.xml;delete_all?feed_item_id=1", {}, nil, 200
    end
  end
  
  def test_update_sends_create_with_each_user_tagging
    require 'tag'
    u1 = users(:quentin)
    u2 = users(:aaron)
    tag1 = Tag(u1, 'test')
    tag2 = Tag(u2, 'test')
    u1.taggings.create(:tag => tag1, :feed_item => FeedItem.find(1))
    u1.taggings.create(:tag => tag1, :feed_item => FeedItem.find(2))
    u2.taggings.create(:tag => tag2, :feed_item => FeedItem.find(2))
    u2.taggings.create(:tag => tag2, :feed_item => FeedItem.find(3))
    u1.taggings.create(:tag => tag1, :feed_item => FeedItem.find(4), :classifier_tagging => true)
    
    ActiveResource::HttpMock.respond_to do |mock|
      mock.delete "/protectors/1/protected_items.xml;delete_all",    {}, nil
      mock.post   "/protectors/1/protected_items.xml", {}, nil, 201
    end
    
    Remote::ProtectedItem.update
    assert req = ActiveResource::HttpMock.requests.detect {|r| r.method == :post }
    items = HashWithIndifferentAccess.new(Hash.from_xml(req.body))
    assert_instance_of(Array, items[:protected_items], items.inspect)
    assert_equal(3, items[:protected_items].size)
    assert_equal([1, 2, 3], items[:protected_items].collect {|item| item['feed_item_id'] })
  end
  
  def test_rebuild_sends_delete_all
    delete_all_path = "/protectors/1/protected_items.xml;delete_all"
    ActiveResource::HttpMock.respond_to do |mock|
      mock.delete delete_all_path,    {}, nil
    end
    
    Remote::ProtectedItem.rebuild
    assert_include ActiveResource::Request.new(:delete, delete_all_path),
                   ActiveResource::HttpMock.requests
  end
  
  def test_rebuild_sends_create_with_each_user_tagging
    require 'tag'
    u1 = users(:quentin)
    u2 = users(:aaron)
    tag1 = Tag(u1, 'test')
    tag2 = Tag(u2, 'test')
    u1.taggings.create(:tag => tag1, :feed_item => FeedItem.find(1))
    u1.taggings.create(:tag => tag1, :feed_item => FeedItem.find(2))
    u2.taggings.create(:tag => tag2, :feed_item => FeedItem.find(2))
    u2.taggings.create(:tag => tag2, :feed_item => FeedItem.find(3))
    u1.taggings.create(:tag => tag1, :feed_item => FeedItem.find(4), :classifier_tagging => true)
    
    ActiveResource::HttpMock.respond_to do |mock|
      mock.delete "/protectors/1/protected_items.xml;delete_all",    {}, nil
      mock.post   "/protectors/1/protected_items.xml", {}, nil, 201
    end
    
    Remote::ProtectedItem.rebuild
    assert req = ActiveResource::HttpMock.requests.detect {|r| r.method == :post }
    items = HashWithIndifferentAccess.new(Hash.from_xml(req.body))
    assert_instance_of(Array, items[:protected_items], items.inspect)
    assert_equal(3, items[:protected_items].size)
    assert_equal([1, 2, 3], items[:protected_items].collect {|item| item['feed_item_id'] })
  end
  
  def test_protect_item_returns_a_thread
    assert_instance_of(Thread, Remote::ProtectedItem.protect_item(FeedItem.find(1)))
  end
  
  def test_unprotect_item_returns_a_thread
    assert_instance_of(Thread, Remote::ProtectedItem.unprotect_item(FeedItem.find(1)))    
  end
  
  def test_protect_item_creates_protected_item
    Remote::ProtectedItem.protect_item(FeedItem.find(1)).join
    assert_include ActiveResource::Request.new(:post, "/protectors/1/protected_items.xml"),
                   ActiveResource::HttpMock.requests
  end
  
  def test_unprotect_item_destroys_protected_item_when_no_taggings_exist
    Remote::ProtectedItem.unprotect_item(FeedItem.find(1)).join
    assert_include ActiveResource::Request.new(:delete, "/protectors/1/protected_items.xml;delete_all?feed_item_id=1"),
                   ActiveResource::HttpMock.requests
  end
  
  def test_unprotect_item_doesnt_destroy_protected_item_when_taggings_exist
    users(:quentin).taggings.create(:tag => Tag(users(:quentin), 'tag'), :feed_item => FeedItem.find(1))
    Remote::ProtectedItem.unprotect_item(FeedItem.find(1)).join
    assert_not_include ActiveResource::Request.new(:delete, "/protectors/1/protected_items.xml;delete_all?feed_item_id=1"),
                   ActiveResource::HttpMock.requests
  end
end