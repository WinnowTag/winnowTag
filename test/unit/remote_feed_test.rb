# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'

class RemoteFeedTest < Test::Unit::TestCase  
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
end