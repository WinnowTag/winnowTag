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
