# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
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
      @user.stub!(:collection_job_result_to_display)
      Feed.stub!(:find_by_url_or_link)
      @feed = mock_model(Feed)
      Feed.stub!(:find_by_id).and_return(@feed)
      @feeds = mock('feeds')
      Feed.stub!(:search).and_return(@feeds)
    end
  
    it "should flash collection result" do
      feed = mock_model(Feed, valid_feed_attributes(:feed_items => mock('feed_items', :size => 10)))
      job = mock_model(CollectionJobResult, :message => "Message", :feed_id => feed.id, :failed? => false, :feed_title => feed.title)
      job.should_receive(:update_attribute).with(:user_notified, true)
      @user.should_receive(:collection_job_result_to_display).and_return(job)
    
      @message = mock_model(Message)
      @messages = stub("messages")
      @messages.should_receive(:create!).with(:body => "We have finished fetching new items for '#{feed.title}'.").and_return(@message)
      @user.stub!(:messages).and_return(@messages)

      get :index
      flash[:notice].should == @message
    end
  
    it "should flash failed collection result" do
      feed = mock_model(Feed, valid_feed_attributes)
      job = mock_model(CollectionJobResult, :message => "Message", :feed => feed, :failed? => true, :feed_title => feed.title)
      job.should_receive(:update_attribute).with(:user_notified, true)
      @user.should_receive(:collection_job_result_to_display).and_return(job)
    
      @message = mock_model(Message)
      @messages = stub("messages")
      @messages.should_receive(:create!).with(:body => "Collection Job for #{feed.title} failed with result: Message").and_return(@message)
      @user.stub!(:messages).and_return(@messages)

      get :index

      flash[:warning].should == @message
    end
  
    describe "#show" do
      it "should assign feed on show" do
        feed = mock_model(Feed, valid_feed_attributes)
        Feed.should_receive(:find).with("12").and_return(feed)
        get 'show', :id => "12"
        assigns[:feed].should == feed
        response.should be_success
      end
  
      it "should try the collector if it can't find the feed locally" do
        Feed.should_receive(:find).with("12").and_raise(ActiveRecord::RecordNotFound)
        feed = mock('feed_1')
        Remote::Feed.should_receive(:find).with("12").and_return(feed)    
        get 'show', :id => "12"
        assigns[:feed].should == feed
        response.should be_success
      end
  
      it "should redirect if collector raises a redirection" do
        Feed.should_receive(:find).with("1").and_raise(ActiveRecord::RecordNotFound)
        collector_response = mock('response', :null_object => true)
        collector_response.stub!(:[]).with('Location').and_return('http://collector/feeds/1234')
        redirection = ActiveResource::Redirection.new(collector_response)
        Remote::Feed.should_receive(:find).with("1").and_raise(redirection)
    
        get 'show', :id => 1
        response.should redirect_to(feed_url(:id => '1234'))
      end
    
      it "should redirect if we have a local duplicate" do
        dup_feed = mock_model(Feed, valid_feed_attributes(:duplicate_id => 1))
        Feed.should_receive(:find).with(dup_feed.id.to_s).and_return(dup_feed)
  
        get 'show', :id => dup_feed.id
        response.should redirect_to(feed_url(:id => '1'))
      end
    
      it "should render 404 if we can't find the feed locally and it can't be found in the collector" do
        Feed.should_receive(:find).with("12").and_raise(ActiveRecord::RecordNotFound)
        Remote::Feed.should_receive(:find).with("12").and_raise(ActiveResource::ResourceNotFound.new(mock('response', :null_object => true)))
      
        get 'show', :id => 12
        flash[:error].should == "We couldn't find this feed in any of our databases.  Maybe it has been deleted or " +
                                "never existed.  If you think this is an error, please contact us."
        response.code.should == "404"
        response.should render_template('feeds/error')
      end
    
      it "should render 503 with nice message if we can't find it and the collector is down" do
        Feed.should_receive(:find).with("12").and_raise(ActiveRecord::RecordNotFound)
        Remote::Feed.should_receive(:find).with("12").and_raise(Errno::ECONNREFUSED)
      
        get 'show', :id => 12
        flash[:error].should == "Sorry, we couldn't find the feed and the main feed database couldn't be contacted. " +
                                "We are aware of this problem and will fix it soon. Please try again later."
        response.code.should == "503"
        response.should render_template('feeds/error')
      end
    end
  
    it "should provide blank url on new" do
      get 'new'
      assigns[:feed].url.should be_nil
    end
  
    it "should re-render form on resource error" do
      feed = mock_model(Remote::Feed)
      feed.errors.should_receive(:empty?).and_return(false)
      feed.errors.should_receive(:on).with(:url).and_return("Error")
      Remote::Feed.should_receive(:find_or_create_by_url).with('http://example.com').and_return(feed)
    
      post 'create', :feed => {:url => 'http://example.com'}
      response.should be_success
      response.should render_template(:new)
      assigns[:feed].should == feed
      flash[:error].should == "Error"
    end
  
    it "should create resource and then collect it " do    
      feed = mock_model(Remote::Feed, :url => 'http://example.com', :updated_on => nil)
      feed.errors.should_receive(:empty?).and_return(true)
      feed.should_receive(:collect)
      Remote::Feed.should_receive(:find_or_create_by_url).with('http://example.com').and_return(feed)
    
      FeedSubscription.should_receive(:find_or_create_by_feed_id_and_user_id).with(feed.id, @user.id)
    
      message_body = "Thanks for adding the feed from 'http://example.com'. " +
                     "We will fetch the items soon and we'll let you know when it is done. " +
                     "The feed has also been added to your feeds folder in the sidebar."
      message = mock_model(Message, :body => message_body)
      messages = mock("messages")
      messages.should_receive(:create!).with(:body => message_body).and_return(message)
      @user.should_receive(:messages).and_return(messages)
    
      post 'create', :feed => {:url => 'http://example.com'}
      response.should redirect_to(feed_path(feed))
      flash[:notice].should == message
    end
  
    it "should collect it a feed even if it already exists" do    
      feed = mock_model(Remote::Feed, :url => 'http://example.com', :updated_on => Time.now)
      feed.errors.should_receive(:empty?).and_return(true)
      feed.should_receive(:collect)
      Remote::Feed.should_receive(:find_or_create_by_url).with('http://example.com').and_return(feed)
    
      FeedSubscription.should_receive(:find_or_create_by_feed_id_and_user_id).with(feed.id, @user.id)
  
      message_body = "We already have the feed from 'http://example.com', however we will update it " +
                     "now and we'll let you know when it is done. " +
                     "The feed has also been added to your feeds folder in the sidebar."
      message = mock_model(Message, :body => message_body)
      messages = mock("messages")
      messages.should_receive(:create!).with(:body => message_body).and_return(message)
      @user.should_receive(:messages).and_return(messages)
  
      post 'create', :feed => {:url => 'http://example.com'}
      response.should redirect_to(feed_path(feed))
      flash[:notice].should == message
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
    
      message_body = "Imported 2 feeds from your OPML file"
      message = mock_model(Message, :body => message_body)
      messages = mock("messages")
      messages.should_receive(:create!).with(:body => message_body).and_return(message)
      @user.should_receive(:messages).and_return(messages)
  
      Remote::Feed.should_receive(:import_opml).
                   with(File.read(File.join(RAILS_ROOT, "spec", "fixtures", "example.opml"))).
                   and_return([mock_feed1, mock_feed2])
      post :import, :opml => fixture_file_upload("example.opml")
      response.should redirect_to(feeds_path)
      flash[:notice].should == message
    end 
  
    it "should create a feed subscription for the subscribe action" do
      subscriptions = mock('subscriptions')
      subscriptions.should_receive(:create).with(:feed_id => @feed.id)
      @user.should_receive(:feed_subscriptions).and_return(subscriptions)
    
      post :subscribe, :id => @feed.id, :subscribe => 'true'
    end
  
    it "should ignore duplicate subscription errors if the user attempts to add a feed more than once" do
      @user.stub!(:messages).and_return(stub("messages", :create! => mock_model(Message)))

      feed = mock_model(Remote::Feed, :url => 'http://example.com', :updated_on => nil)
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
  
    describe "create" do
      it "renders the rjs template on a javascript call" do
        @user.stub!(:messages).and_return(stub("messages", :create! => mock_model(Message)))
        
        feed = mock_model(Remote::Feed, :url => 'http://example.com', :updated_on => Time.now, :collect => nil)
        feed.errors.stub!(:empty?).and_return(true)
        Remote::Feed.stub!(:find_or_create_by_url).with('http://example.com').and_return(feed)
        FeedSubscription.stub!(:find_or_create_by_feed_id_and_user_id)
    
        post :create, :feed => {:url => 'http://example.com'}, :format => 'js'
        response.should render_template("create")
      end
    end
  
    describe "auto_complete_for_feed_title" do
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
