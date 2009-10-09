# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

require File.dirname(__FILE__) + '/../spec_helper'

describe FeedManager, '#create' do
  
  it "finds or creates the feed remotely" do
    @user = mock_model(User, :login => "jdoe")
    remote_feed = mock_model(Remote::Feed,
                             :valid? => false,
                             :errors => stub("errors", :full_messages => stub("full_messages", :to_sentence => "")))
    Remote::Feed.should_receive(:find_or_create_by_url_and_created_by).with("feed_url", "jdoe").and_return(remote_feed)
    FeedManager.create(@user, "feed_url", "collection_job_results_url")
  end
  
  context "when the remote feed is invalid" do
    
    it "indicates failure" do
      @user = mock_model(User, :login => "jdoe")
      remote_feed = mock_model(Remote::Feed,
                               :valid? => false,
                               :errors => stub("errors", :full_messages => stub("full_messages", :to_sentence => "")))
      multiblock = stub("multiblock")
      Remote::Feed.stub!(:find_or_create_by_url_and_created_by).and_return(remote_feed)
      Multiblock.should_receive(:[]).with(:failed, remote_feed, "").and_return(multiblock)
      FeedManager.create(@user, "feed_url", "collection_job_results_url").should == multiblock
    end
    
  end
  
  context "when the remote feed is valid" do
    
    before(:each) do
      @user = mock_model(User, :login => "jdoe")
      @remote_feed = mock_model(Remote::Feed, :valid? => true, :collect => nil, :uri => "foo", :url => "bar")
      @feed = mock_model(Feed, :via => "foo")
      
      Remote::Feed.stub!(:find_or_create_by_url_and_created_by).and_return(@remote_feed)
      Feed.stub!(:find_by_uri).and_return(@feed)
    end
    
    it "collects the remote feed" do
      @remote_feed.should_receive(:collect).with(:created_by => "jdoe", :callback_url => "collection_job_results_url")
      FeedManager.create(@user, "feed_url", "collection_job_results_url")
    end
    
    it "starts a transaction" do
      Feed.should_receive(:transaction).with().and_yield
      FeedManager.create(@user, "feed_url", "collection_job_results_url")
    end
    
    context "in a transaction" do
      before(:each) do
        Feed.stub!(:transaction).and_yield
        
        @multiblock = stub("multiblock")
      end
      
      it "tries to find the feed" do
        Feed.should_receive(:find_by_uri).with(@remote_feed.uri).and_return(@feed)
        FeedManager.create(@user, "feed_url", "collection_job_results_url")
      end
      
      context "when the feed is found" do
        it "indicates success" do
          message = I18n.t("winnow.notifications.feed_existed", :url => h(@feed.via))
          Multiblock.should_receive(:[]).with(:success, @feed, message).and_return(@multiblock)
          FeedManager.create(@user, "feed_url", "collection_job_results_url").should == @multiblock
        end
      end
      
      context "when the feed is not found" do
        before(:each) do
          Feed.stub!(:find_by_uri).and_return(nil)
        end
        
        it "creates the feed" do
          Multiblock.stub!(:[]).and_return(@multiblock)
          Feed.should_receive(:create!).with(:uri => @remote_feed.uri, :via => @remote_feed.url).and_return(@feed)
          FeedManager.create(@user, "feed_url", "collection_job_results_url").should == @multiblock
        end
        
        it "indicates success" do
          Feed.stub!(:create!).and_return(@feed)
          message = I18n.t("winnow.notifications.feed_added", :url => h(@feed.via))
          Multiblock.should_receive(:[]).with(:success, @feed, message).and_return(@multiblock)
          FeedManager.create(@user, "feed_url", "collection_job_results_url").should == @multiblock
        end
      end
    end
    
    it "subscribes the @user to the feed" do
      FeedSubscription.should_receive(:find_or_create_by_feed_id_and_user_id).with(@feed.id, @user.id)
      FeedManager.create(@user, "feed_url", "collection_job_results_url")
    end
    
  end
  
end
