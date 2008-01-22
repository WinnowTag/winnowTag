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
    @feed = mock_model(Feed)
    Feed.stub!(:find_by_id).and_return(@feed)
    @feeds = mock('feeds')
    Feed.stub!(:search).and_return(@feeds)
  end
  
  it "should assign feeds on all" do    
    get 'all'
    assigns[:feeds].should == @feeds
  end
  
  it "should assign feed on show" do
    feed = mock('feed_1')
    feed.stub!(:duplicate)
    Feed.should_receive(:find).with("1").and_return(feed)
    get 'show', :id => 1
    assigns[:feed].should == feed
  end

  it "should re-render form on resource error" do
    feed = mock_model(Remote::Feed)
    feed.errors.should_receive(:empty?).and_return(false)
    feed.errors.should_receive(:on).with(:url).and_return("Error")
    Remote::Feed.should_receive(:find_or_create_by_url).with('http://example.com').and_return(feed)
    
    post 'create', :feed => {:url => 'http://example.com'}
    response.should be_success
    response.should render_template(:new)
    flash[:error].should == "Error"
  end
  
  it "should create resource" do    
    feed = mock_model(Remote::Feed, :url => 'http://example.com')
    feed.errors.should_receive(:empty?).and_return(true)
    feed.should_receive(:collect)
    Remote::Feed.should_receive(:find_or_create_by_url).with('http://example.com').and_return(feed)
    
    FeedSubscription.should_receive(:find_or_create_by_feed_id_and_user_id).with(feed.id, @user.id)
    
    post 'create', :feed => {:url => 'http://example.com'}
    response.should redirect_to(feed_path(feed))
  end
  
  it "should flash collection result" do
    feed = mock_model(Feed, valid_feed_attributes(:feed_items => mock('feed_items', :size => 10)))
    job = mock_model(CollectionJobResult, :message => "Message", :feed => feed, :failed? => false, :feed_title => feed.title)
    job.should_receive(:update_attribute).with(:user_notified, true)
    @user.should_receive(:collection_job_result_to_display).and_return(job)
    
    get :all
    flash[:notice].should == "The feed you requested '#{feed.title}' now has 10 items."
  end
  
  it "should flash failed collection result" do
    feed = mock_model(Feed, valid_feed_attributes)
    job = mock_model(CollectionJobResult, :message => "Message", :feed => feed, :failed? => true, :feed_title => feed.title)
    job.should_receive(:update_attribute).with(:user_notified, true)
    @user.should_receive(:collection_job_result_to_display).and_return(job)
    
    get :all
    flash[:warning].should =~ /Collection Job for #{feed.title} failed with result: Message/
  end
  
  it "should render import form" do
    get :import
    response.should be_success
    response.should render_template("feeds/import")
  end
  
  it "should import feeds from opml" do
    mock_feed1 = mock_model(Remote::Feed)
    mock_feed2 = mock_model(Remote::Feed)
    mock_feed1.should_receive(:collect)
    mock_feed2.should_receive(:collect)
    
    FeedSubscription.should_receive(:find_or_create_by_feed_id_and_user_id).with(mock_feed1.id, @user.id)
    FeedSubscription.should_receive(:find_or_create_by_feed_id_and_user_id).with(mock_feed2.id, @user.id)
    
    Remote::Feed.should_receive(:import_opml).
                 with(File.read(File.join(RAILS_ROOT, "spec", "fixtures", "example.opml"))).
                 and_return([mock_feed1, mock_feed2])
    post :import, :opml => fixture_file_upload("example.opml")
    response.should redirect_to(feeds_path)
    flash[:notice].should == "Imported 2 feeds from your OPML file"
  end 
  
  it "should create a feed subscription for the subscribe action" do
    subscriptions = mock('subscriptions')
    subscriptions.should_receive(:create).with(:feed_id => @feed.id)
    @user.should_receive(:feed_subscriptions).and_return(subscriptions)
    
    post :subscribe, :id => @feed.id, :subscribe => 'true'
  end
  
  it "should ignore duplicate subscription errors if the user attempts to add a feed more than once" do
    feed = mock_model(Remote::Feed, :url => 'http://example.com')
    feed.errors.should_receive(:empty?).and_return(true)
    feed.should_receive(:collect)
    Remote::Feed.should_receive(:find_or_create_by_url).with('http://example.com').and_return(feed)
    
    FeedSubscription.should_receive(:find_or_create_by_feed_id_and_user_id).with(feed.id, @user.id).and_raise(ActiveRecord::StatementInvalid)
    
    post 'create', :feed => {:url => 'http://example.com'}
    response.should redirect_to(feed_path(feed))
  end
  
  it "should ignore double subscriptions" do
    subscriptions = mock('subscriptions')
    subscriptions.should_receive(:create).with(:feed_id => @feed.id).and_raise(ActiveRecord::StatementInvalid)
    @user.should_receive(:feed_subscriptions).and_return(subscriptions)
    
    post :subscribe, :id => @feed.id, :subscribe => 'true'
  end
end
