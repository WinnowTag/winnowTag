# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'
require 'active_resource/http_mock'

describe Remote::Feed do
  fixtures :feeds
  before(:each) do
    now = Time.parse("Thu, 10 Jul 2008 03:29:56 GMT")
    Time.should_receive(:now).at_least(1).and_return(now)
  end
  
  it "should send import_opml messages" do
    ActiveResource::HttpMock.respond_to do |http|
      http.post "/feeds/import_opml.xml", 
        {"Authorization" => "AuthHMAC winnow_id:qcSBTcXB/DPo4AatdqvnpRdzeA4=", "Content-Type" => "text/x-opml", 'Date' => "Thu, 10 Jul 2008 03:29:56 GMT"}, 
        [Feed.find(1)].to_xml, 200
    end
    
    feeds = Remote::Feed.import_opml(File.read(File.join(RAILS_ROOT, 'spec', 'fixtures', 'example.opml')))
    feeds.should == [Remote::Feed.new(Feed.find(1).attributes)]
  end
    
  it "collect_creates_new_collection_job" do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.post "/feeds/1/collection_jobs.xml",
        {"Authorization" => "AuthHMAC winnow_id:A5tNxOwPuabChDo4oPLWvb6RyPs=", "Content-Type" => "application/xml", 'Date' => "Thu, 10 Jul 2008 03:29:56 GMT"},
        nil, 201, 'Location' => '/feeds/1/collection_jobs/3'
    end
    job = Remote::Feed.new(:id => 1).collect
    assert_equal 3, job.id.to_i
  end
  
  it "collect_sets_user" do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.post "/feeds/1/collection_jobs.xml",
        {"Authorization" => "AuthHMAC winnow_id:A5tNxOwPuabChDo4oPLWvb6RyPs=", "Content-Type" => "application/xml", 'Date' => "Thu, 10 Jul 2008 03:29:56 GMT"},
        nil, 201, 'Location' => '/feeds/1/collection_jobs/3'
    end
    job = Remote::Feed.new(:id => 1).collect(:created_by => 'seangeo')
    assert_equal 'seangeo', job.created_by
  end
  
  it "collect_sets_callback_url" do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.post "/feeds/1/collection_jobs.xml",
        {"Authorization" => "AuthHMAC winnow_id:A5tNxOwPuabChDo4oPLWvb6RyPs=", "Content-Type" => "application/xml", 'Date' => "Thu, 10 Jul 2008 03:29:56 GMT"},
        nil, 201, 'Location' => '/feeds/1/collection_jobs/3'
    end
    job = Remote::Feed.new(:id => 1).collect(:callback_url => 'http://localhost/callback')
    assert_equal "http://localhost/callback", job.callback_url
  end
  
  it "should map alternate to link" do
    ActiveResource::HttpMock.respond_to do |http|
      http.get "/feeds/23.xml", 
        {"Authorization" => "AuthHMAC winnow_id:SyNewUAs1BjEd8+8/JmqW4heQMI=", "Accept" => "application/xml", 'Date' => "Thu, 10 Jul 2008 03:29:56 GMT"},
        {:url => 'http://example.com', :link => 'http://example.com/html'}.to_xml(:root => 'feed'), 201, 'Location' => '/feeds/23'
    end

    feed = Remote::Feed.find("23")
    feed.alternate.should == 'http://example.com/html'
  end
  
  it "should map via to url" do
    ActiveResource::HttpMock.respond_to do |http|
      http.get "/feeds/23.xml", 
        {"Authorization" => "AuthHMAC winnow_id:SyNewUAs1BjEd8+8/JmqW4heQMI=", "Accept" => "application/xml", 'Date' => "Thu, 10 Jul 2008 03:29:56 GMT"},
        {:url => 'http://example.com', :link => 'http://example.com/html'}.to_xml(:root => 'feed'), 201, 'Location' => '/feeds/23'
    end
    
    feed = Remote::Feed.find("23")
    feed.via.should == 'http://example.com'
  end
  
  it "find_or_create_by_url" do
    ActiveResource::HttpMock.respond_to do |http|
      http.post "/feeds.xml",
        {"Authorization" => "AuthHMAC winnow_id:HpYILSABqZYTFkEVKfDWZglB7GY=", "Content-Type" => "application/xml", 'Date' => "Thu, 10 Jul 2008 03:29:56 GMT"},
        {:url => 'http://example.com', :created_by => 'quentin'}.to_xml(:root => 'feed'), 201, 'Location' => '/feeds/23'
    end
    
    job = Remote::Feed.find_or_create_by_url_and_created_by("http://example.com", 'quentin')
    assert_equal "http://example.com", job.url
    assert_equal "23", job.id
    assert job.errors.empty?
  end
  
  it "find_or_create_by_url_with_duplicate    " do
    ActiveResource::HttpMock.respond_to do |http|
      http.post "/feeds.xml", 
        {"Authorization" => "AuthHMAC winnow_id:HpYILSABqZYTFkEVKfDWZglB7GY=", "Content-Type" => "application/xml", 'Date' => "Thu, 10 Jul 2008 03:29:56 GMT"}, 
        {:url => 'http://example.com', :created_by => 'quentin'}.to_xml(:root => 'feed'), 302, 'Location' => '/feeds/24'
      http.get "/feeds/24.xml", 
        {"Authorization" => "AuthHMAC winnow_id:duRJowCjTYd7xrSFEkXfyS8hono=", "Accept" => "application/xml", 'Date' => "Thu, 10 Jul 2008 03:29:56 GMT"}, 
        {:url => 'http://www.example.com', :id => 24, :created_by => 'quentin'}.to_xml(:root => 'feed'), 200
    end

    job = Remote::Feed.find_or_create_by_url_and_created_by("http://example.com", 'quentin')
    assert_equal "http://www.example.com", job.url
    assert_equal 24, job.id
    job.created_by.should == 'quentin'
    assert job.errors.empty?
  end
  
  it "find_or_create_by_url_with_redirect_loop_raises_exception" do
    ActiveResource::HttpMock.respond_to do |http|
      http.post "/feeds.xml", 
        {"Authorization" => "AuthHMAC winnow_id:HpYILSABqZYTFkEVKfDWZglB7GY=", "Content-Type" => "application/xml", 'Date' => "Thu, 10 Jul 2008 03:29:56 GMT"}, 
        {:url => 'http://example.com'}.to_xml(:root => 'feed'), 302, 'Location' => '/feeds/24'
      http.get "/feeds/24.xml", 
        {"Authorization" => "AuthHMAC winnow_id:duRJowCjTYd7xrSFEkXfyS8hono=", "Accept" => "application/xml", 'Date' => "Thu, 10 Jul 2008 03:29:56 GMT"}, 
        nil, 302, 'Location' => '/feeds/24'
    end

    assert_raise(ActiveResource::Redirection) { job = Remote::Feed.find_or_create_by_url_and_created_by('http://example.com', 'quentin') }    
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