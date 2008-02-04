# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../spec_helper'

describe Remote::ProtectedItem do
  fixtures :users, :feed_items

  before(:each) do
    Protector.create(:protector_id => 1)
    ActiveResource::HttpMock.respond_to do |http|
      http.post "/protectors/1/protected_items.xml", {}, nil, 201, 'Location' => '/protectors/1/protected_items/2'
      http.delete "/protectors/1/protected_items/delete_all.xml?feed_item_id=1", {}, nil, 200
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
      mock.delete "/protectors/1/protected_items/delete_all.xml",    {}, nil
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
    delete_all_path = "/protectors/1/protected_items/delete_all.xml"
    ActiveResource::HttpMock.respond_to do |mock|
      mock.delete delete_all_path,    {}, nil
    end

    Remote::ProtectedItem.should_receive(:update)
    Remote::ProtectedItem.rebuild
    
    ActiveResource::HttpMock.requests.should include(ActiveResource::Request.new(:delete, delete_all_path))
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
      mock.delete "/protectors/1/protected_items/delete_all.xml",    {}, nil
      mock.post   "/protectors/1/protected_items.xml", {}, nil, 201
    end
    
    Remote::ProtectedItem.rebuild
    assert req = ActiveResource::HttpMock.requests.detect {|r| r.method == :post }
    items = HashWithIndifferentAccess.new(Hash.from_xml(req.body))
    assert_instance_of(Array, items[:protected_items], items.inspect)
    assert_equal(3, items[:protected_items].size)
    assert_equal([1, 2, 3], items[:protected_items].collect {|item| item['feed_item_id'] })
  end  
end