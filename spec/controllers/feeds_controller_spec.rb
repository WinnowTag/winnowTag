# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../spec_helper'

describe FeedsController do
  before(:each) do
    login_as(1)
    mock_user_for_controller
    @user.stub!(:collection_job_result_to_display)
    Feed.stub!(:find_by_url_or_link)
    @feeds = mock('feeds')
    Feed.stub!(:search).and_return(@feeds)
  end
  
  it "should assign feeds on index" do    
    get 'index', :view_id => 1
    assigns[:feeds].should == @feeds
  end
  
  it "should assign feed on show" do
    feed = mock('feed_1')
    Feed.should_receive(:find).with("1").and_return(feed)
    get 'show', :id => 1, :view_id => 1
    assigns[:feed].should == feed
  end

  it "should re-render form on resource error" do
    feed = mock_model(Remote::Feed)
    feed.should_receive(:save).and_return(false)
    feed.errors.should_receive(:on).with(:url).and_return("Error")
    Remote::Feed.should_receive(:new).with("url" => 'http://example.com').and_return(feed)
    
    post 'create', :feed => {:url => 'http://example.com'}, :view_id => 1
    response.should be_success
    response.should render_template(:new)
    flash[:error].should == "Error"
  end
  
  it "should create resource when no duplicates exist" do
    feed = mock_model(Remote::Feed, :url => 'http://example.com')
    feed.should_receive(:save).and_return(true)
    feed.stub!(:collect)
    Remote::Feed.should_receive(:new).with("url" => 'http://example.com').and_return(feed)
    
    post 'create', :feed => {:url => 'http://example.com'}, :view_id => 1
    response.should redirect_to(feed_path(feed))    
  end
  
  it "should redirect to existing feed on duplicate" do
    feed = mock_model(Feed, valid_feed_attributes)
    Feed.should_receive(:find_by_url_or_link).with('http://example.com').and_return(feed)
    Remote::Feed.should_receive(:new).never
    
    post 'create', :feed => {:url => 'http://example.com'}, :view_id => @view.id
    response.should redirect_to(feed_url(feed, :view_id => @view.id))
  end
  
  it "should flash collection result" do
    feed = mock_model(Feed, valid_feed_attributes)
    job = mock_model(CollectionJobResult, :message => "Message", :feed => feed, :failed? => false, :feed_title => feed.title)
    job.should_receive(:update_attribute).with(:user_notified, true)
    @user.should_receive(:collection_job_result_to_display).and_return(job)
    
    get :index, :view_id => 1
    flash[:notice].should =~ /Collection Job for #{feed.title} completed with result: Message/
  end
  
  it "should flash failed collection result" do
    feed = mock_model(Feed, valid_feed_attributes)
    job = mock_model(CollectionJobResult, :message => "Message", :feed => feed, :failed? => true, :feed_title => feed.title)
    job.should_receive(:update_attribute).with(:user_notified, true)
    @user.should_receive(:collection_job_result_to_display).and_return(job)
    
    get :index, :view_id => 1
    flash[:warning].should =~ /Collection Job for #{feed.title} failed with result: Message/
  end
end