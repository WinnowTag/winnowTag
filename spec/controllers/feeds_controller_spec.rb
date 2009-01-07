# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe FeedsController do
  describe "#index" do
    before(:each) do
      @user = User.create! valid_user_attributes
      login_as @user
    end

    def do_get(params = {})
      get :index, params
    end
    
    it "is a success" do
      do_get
      response.should be_success
    end
    
    it "renders the index template" do
      do_get
      response.should render_template("index")
    end
  end
    
  describe "old specs" do
  
    before(:each) do
      login_as(1)
      mock_user_for_controller
    end
  
    it "should re-render form on resource error" do
      feed = mock_model(Remote::Feed)
      feed.errors.should_receive(:empty?).and_return(false)
      feed.errors.should_receive(:on).with(:url).and_return("Error")
      Remote::Feed.should_receive(:find_or_create_by_url_and_created_by).with('http://example.com', @user.login).and_return(feed)
    
      post 'create', :feed => {:url => 'http://example.com'}
      response.should be_success
      response.should render_template("index")
      assigns[:remote_feed].should == feed
      flash[:error].should == "Error"
    end
  
    it "should create resource and then collect it " do    
      remote_feed = mock_model(Remote::Feed, :uri => "uri1", :url => 'http://example.com')
      remote_feed.errors.should_receive(:empty?).and_return(true)
      remote_feed.should_receive(:collect)
      Remote::Feed.should_receive(:find_or_create_by_url_and_created_by).with('http://example.com', @user.login).and_return(remote_feed)
    
      feed = mock_model(Feed, :uri => "uri1", :via => "http://example.com")
      Feed.should_receive(:find_by_uri).with("uri1").and_return(nil)
      Feed.should_receive(:create!).with(:uri => "uri1", :via => "http://example.com").and_return(feed)


    
      FeedSubscription.should_receive(:find_or_create_by_feed_id_and_user_id).with(feed.id, @user.id)
    
      post 'create', :feed => {:url => 'http://example.com'}
      response.should redirect_to(feeds_path)
      flash[:notice].should == "Thanks for adding the feed from http://example.com. We will fetch the items soon. " + 
                               "The feed has also been added to your feeds folder in the sidebar."
    end
  
    it "should collect it a feed even if it already exists" do    
      remote_feed = mock_model(Remote::Feed, :uri => "uri1", :url => 'http://example.com')
      remote_feed.errors.should_receive(:empty?).and_return(true)
      remote_feed.should_receive(:collect)
      Remote::Feed.should_receive(:find_or_create_by_url_and_created_by).with('http://example.com', @user.login).and_return(remote_feed)
    
      feed = mock_model(Feed, :uri => "uri1", :via => "http://example.com")
      Feed.should_receive(:find_by_uri).with("uri1").and_return(feed)
      Feed.should_not_receive(:create!)

      FeedSubscription.should_receive(:find_or_create_by_feed_id_and_user_id).with(feed.id, @user.id)
  
      post 'create', :feed => { :url => 'http://example.com' }
      response.should redirect_to(feeds_path)
      flash[:notice].should == "We already have the feed from http://example.com, however we will update it now. " + 
                               "The feed has also been added to your feeds folder in the sidebar."
    end
    
    it "should reject a feed from winnow" do
      post 'create', :feed => {:url => 'http://test.host'}
      flash[:error].should == "Winnow generated feeds cannot be added to Winnow."
    end
      
    it "should not raise an error when the feed URL is invalid" do
      feed = mock_model(Remote::Feed)
      feed.errors.should_receive(:empty?).and_return(false)
      feed.errors.should_receive(:on).with(:url).and_return("Error")
      Remote::Feed.should_receive(:find_or_create_by_url_and_created_by).with('http://feed_does_not_exist_test.com/blog', @user.login).and_return(feed)
      
      post 'create', :feed => {:url => 'http://feed_does_not_exist_test.com/blog'}
      response.should be_success
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
      @feed = Feed.create! :uri => "some uri"
      
      lambda {
        post :subscribe, :id => @feed.id, :subscribe => 'true'
      }.should change(FeedSubscription, :count).by(1)
    end
  
    it "should ignore double subscriptions" do
      @feed = Feed.create! :uri => "some uri"

      post :subscribe, :id => @feed.id, :subscribe => 'true'

      lambda {
        post :subscribe, :id => @feed.id, :subscribe => 'true'
      }.should change(FeedSubscription, :count).by(0)
    end
  
    describe "create" do
      it "renders the rjs template on a javascript call" do
        @user.stub!(:messages).and_return(stub("messages", :create! => mock_model(Message)))
        
        feed = mock_model(Remote::Feed, :uri => "uri1", :url => 'http://example.com', :updated_on => Time.now, :collect => nil)
        feed.errors.stub!(:empty?).and_return(true)
        Remote::Feed.stub!(:find_or_create_by_url_and_created_by).with('http://example.com', @user.login).and_return(feed)
        FeedSubscription.stub!(:find_or_create_by_feed_id_and_user_id)
    
        post :create, :feed => {:url => 'http://example.com'}, :format => 'js'
        response.should render_template("create")
      end
    end
  
    describe "auto_complete_for_feed_title" do
      fixtures :feeds
      
      before(:each) do
        @user.stub!(:subscribed_feeds).and_return([])
      end
    
      it "should return all feeds with matching title" do
        get :auto_complete_for_feed_title, :feed => { :title => 'Ruby'}
        assigns[:feeds].size.should == 2
      end
    
      it "should not return duplicate feeds" do
        Feed.create!(valid_feed_attributes(:title => 'Ruby', :duplicate_id => 1))
        get :auto_complete_for_feed_title, :feed => { :title => 'Ruby'}
        assigns[:feeds].size.should == 2
      end
    end
  end
end
