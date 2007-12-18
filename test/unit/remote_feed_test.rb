# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'

class RemoteFeedTest < Test::Unit::TestCase
  def setup
    ActiveResource::Base.logger = ActiveRecord::Base.logger
  end
  
  def test_collect_creates_new_collection_job
    ActiveResource::HttpMock.respond_to do |mock|
      mock.post   "/feeds/1/collection_jobs.xml",   {}, nil, 201, 'Location' => '/feeds/1/collection_jobs/3'
    end
    job = Remote::Feed.new(:id => 1).collect
    assert_equal 3, job.id.to_i
  end
  
  def test_collect_sets_user
    ActiveResource::HttpMock.respond_to do |mock|
      mock.post   "/feeds/1/collection_jobs.xml",   {}, nil, 201, 'Location' => '/feeds/1/collection_jobs/3'
    end
    job = Remote::Feed.new(:id => 1).collect(:created_by => 'seangeo')
    assert_equal 'seangeo', job.created_by
  end
  
  def test_collect_sets_callback_url
    ActiveResource::HttpMock.respond_to do |mock|
      mock.post   "/feeds/1/collection_jobs.xml",   {}, nil, 201, 'Location' => '/feeds/1/collection_jobs/3'
    end
    job = Remote::Feed.new(:id => 1).collect(:callback_url => 'http://localhost/callback')
    assert_equal "http://localhost/callback", job.callback_url
  end
  
  def test_find_or_create_by_url
    ActiveResource::HttpMock.respond_to do |http|
      http.post  "/feeds.xml", {}, {:url => 'http://example.com'}.to_xml(:root => 'feed'), 201, 'Location' => '/feeds/23'
    end
    
    job = Remote::Feed.find_or_create_by_url("http://example.com")
    assert_equal "http://example.com", job.url
    assert_equal "23", job.id
    assert job.errors.empty?
  end
  
  def test_find_or_create_by_url_with_duplicate    
    ActiveResource::HttpMock.respond_to do |http|
      http.post  "/feeds.xml", {}, {:url => 'http://example.com'}.to_xml(:root => 'feed'), 302, 'Location' => '/feeds/24'
      http.get   "/feeds/24.xml", {}, {:url => 'http://www.example.com', :id => 24}.to_xml(:root => 'feed'), 200
    end
    
    job = Remote::Feed.find_or_create_by_url("http://example.com")
    assert_equal "http://www.example.com", job.url
    assert_equal 24, job.id
    assert job.errors.empty?
  end
  
  def test_find_or_create_by_url_with_redirect_loop_raises_exception
    ActiveResource::HttpMock.respond_to do |http|
      http.post  "/feeds.xml", {}, {:url => 'http://example.com'}.to_xml(:root => 'feed'), 302, 'Location' => '/feeds/24'
      http.get   "/feeds/24.xml", {}, nil, 302, 'Location' => '/feeds/24'
    end
    
    assert_raise(ActiveResource::Redirection) { job = Remote::Feed.find_or_create_by_url('http://example.com') }    
  end
end