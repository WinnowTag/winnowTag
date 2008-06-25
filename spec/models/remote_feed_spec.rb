# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
require File.dirname(__FILE__) + '/../spec_helper'
require 'active_resource/http_mock'

describe Remote::Feed do
  fixtures :feeds
  
  it "should send import_opml messages" do
    ActiveResource::HttpMock.respond_to do |http|
      http.post '/feeds/import_opml.xml', {"Content-Type" => "text/x-opml"}, [Feed.find(1)].to_xml, 200
    end
    
    feeds = Remote::Feed.import_opml(File.read(File.join(RAILS_ROOT, 'spec', 'fixtures', 'example.opml')))
    feeds.should == [Remote::Feed.new(Feed.find(1).attributes)]
  end
    
  it "collect_creates_new_collection_job" do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.post   "/feeds/1/collection_jobs.xml",   {}, nil, 201, 'Location' => '/feeds/1/collection_jobs/3'
    end
    job = Remote::Feed.new(:id => 1).collect
    assert_equal 3, job.id.to_i
  end
  
  it "collect_sets_user" do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.post   "/feeds/1/collection_jobs.xml",   {}, nil, 201, 'Location' => '/feeds/1/collection_jobs/3'
    end
    job = Remote::Feed.new(:id => 1).collect(:created_by => 'seangeo')
    assert_equal 'seangeo', job.created_by
  end
  
  it "collect_sets_callback_url" do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.post   "/feeds/1/collection_jobs.xml",   {}, nil, 201, 'Location' => '/feeds/1/collection_jobs/3'
    end
    job = Remote::Feed.new(:id => 1).collect(:callback_url => 'http://localhost/callback')
    assert_equal "http://localhost/callback", job.callback_url
  end
  
  it "should map alternate to link" do
    ActiveResource::HttpMock.respond_to do |http|
      http.get  "/feeds/23.xml", {}, {:url => 'http://example.com', :link => 'http://example.com/html'}.to_xml(:root => 'feed'), 201, 'Location' => '/feeds/23'
    end
    
    feed = Remote::Feed.find("23")
    feed.alternate.should == 'http://example.com/html'
  end
  
  it "should map via to url" do
    ActiveResource::HttpMock.respond_to do |http|
      http.get  "/feeds/23.xml", {}, {:url => 'http://example.com', :link => 'http://example.com/html'}.to_xml(:root => 'feed'), 201, 'Location' => '/feeds/23'
    end
    
    feed = Remote::Feed.find("23")
    feed.via.should == 'http://example.com'
  end
  
  it "find_or_create_by_url" do
    ActiveResource::HttpMock.respond_to do |http|
      http.post  "/feeds.xml", {}, {:url => 'http://example.com'}.to_xml(:root => 'feed'), 201, 'Location' => '/feeds/23'
    end
    
    job = Remote::Feed.find_or_create_by_url("http://example.com")
    assert_equal "http://example.com", job.url
    assert_equal "23", job.id
    assert job.errors.empty?
  end
  
  it "find_or_create_by_url_with_duplicate    " do
    ActiveResource::HttpMock.respond_to do |http|
      http.post  "/feeds.xml", {}, {:url => 'http://example.com'}.to_xml(:root => 'feed'), 302, 'Location' => '/feeds/24'
      http.get   "/feeds/24.xml", {}, {:url => 'http://www.example.com', :id => 24}.to_xml(:root => 'feed'), 200
    end
    
    job = Remote::Feed.find_or_create_by_url("http://example.com")
    assert_equal "http://www.example.com", job.url
    assert_equal 24, job.id
    assert job.errors.empty?
  end
  
  it "find_or_create_by_url_with_redirect_loop_raises_exception" do
    ActiveResource::HttpMock.respond_to do |http|
      http.post  "/feeds.xml", {}, {:url => 'http://example.com'}.to_xml(:root => 'feed'), 302, 'Location' => '/feeds/24'
      http.get   "/feeds/24.xml", {}, nil, 302, 'Location' => '/feeds/24'
    end
    
    assert_raise(ActiveResource::Redirection) { job = Remote::Feed.find_or_create_by_url('http://example.com') }    
  end
  
  describe "attributes" do
    {:title => "is this thing on?", :updated_on => Date.today}.each do |attribute, value|
      it "responds to #{attribute} when not given one" do
        feed = Remote::Feed.new
        feed.should respond_to(attribute)
      end
    
      it "can be given #{attribute} as an attribute" do
        feed = Remote::Feed.new attribute => value
        feed.send(attribute).should == value
      end
    end
  end
end