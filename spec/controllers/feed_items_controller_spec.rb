# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe FeedItemsController do
  it "requires_login" do
    assert_requires_login { |c| c.get :index, {} }
  end

  describe "GET /feed_items" do
    def get_index
      get :index
    end
    
    before(:each) do
      login_as Generate.user!
    end
    
    it "is successful" do
      get_index
      response.should be_success
    end

    it "renders the index template" do
      get_index
      response.should render_template("index")
    end
  end
  
  describe "GET /feed_items.json" do
    def get_index(params = {})
      get :index, params.merge(:format => "json")
    end
    
    before(:each) do
      login_as Generate.user!
    end
    
    it "is successful" do
      get_index
      response.should be_success
    end

    it "renders the index template" do
      get_index
      response.should render_template("index")
    end
    
    it "sets feed items for the view" do
      get_index
      assigns[:feed_items].should_not be_nil
    end

    it "logs a tag usage linked to the current user for each requested tag" do
      tag1, tag2 = stub("tag1"), stub("tag2")
      Tag.should_receive(:find_by_id).with("1").and_return(tag1)
      Tag.should_receive(:find_by_id).with("2").and_return(tag2)
      TagUsage.should_receive(:create!).with(:tag => tag1, :user => current_user)
      TagUsage.should_receive(:create!).with(:tag => tag2, :user => current_user)
    
      get_index :tag_ids => "1,2"
    end

    it "does not attempt to log a tag usage when the requested tag does not exist" do
      get_index :tag_ids => "1"
    end
  end
  
  describe "GET /feed_items.atom" do
    def get_index(params = {})
      get :index, params.merge(:format => "atom")
    end
    
    before(:each) do
      login_as Generate.user!
    end
    
    it "is successful" do
      get_index
      response.should be_success
    end

    it "logs a tag usage linked to the current user for each requested tag" do
      tag1 = Generate.tag!
      tag2 = Generate.tag!
      
      TagUsage.should_receive(:create!).with(:tag_id => tag1.id.to_s, :user_id => current_user.id)
      TagUsage.should_receive(:create!).with(:tag_id => tag2.id.to_s, :user_id => current_user.id)
    
      get_index :tag_ids => [tag1.id, tag2.id].join(",")
    end
  end
    
  it "body" do
    feed_item = Generate.feed_item!
    
    login_as Generate.user!
    get :body, :id => feed_item.id, :format => "js"
    response.should be_success
    response.should render_template("body")
  end
  
  describe "/clues" do
    before(:each) do
      user = Generate.user!
      @tag = Generate.tag!

      login_as user
      
      @http_response = mock('response')
      @http_response.stub!(:code).and_return("200")
      @http_response.stub!(:body).and_return([{'clue' => 'bar', 'prob' => 0.01}, {'clue' => 'foo', 'prob' => 0.99}].to_json)
      Remote::ClassifierResource.site = "http://classifier.host/classifier"
      tag_url = URI.escape("http://test.host/#{user.login}/tags/#{@tag.name}/training.atom")
      item_url = URI.escape('urn:peerworks.org:entry#1234')
      url = %Q|#{Remote::ClassifierResource.site}/clues?tag=#{tag_url}&item=#{item_url}|
      http = mock('http')
      http.should_receive(:request) do |request|
        request['Authorization'].should_not be_nil
        @http_response
      end
      Net::HTTP.should_receive(:start).with('classifier.host', 80).and_yield(http)
    end
    
    it "should render the clues" do
      get :clues, :format => "js", :id => 1234, :tag => @tag.id
      response.should be_success
      response.should render_template("clues")
    end
    
    describe "with 424 status code from the classifier" do
      before(:each) do
        @http_response.stub!(:code).and_return("424")
      end
      
      it "should result in a redirect with the tries parameter set" do
        get :clues, :id => 1234, :tag => @tag.id
        response.should redirect_to("/feed_items/1234/clues?tag=#{@tag.id}&tries=1")
      end
      
      it "should result in a redirect with the tries parameter incremented" do
        get :clues, :id => 1234, :tag => @tag.id, :tries => 4
        response.should redirect_to("/feed_items/1234/clues?tag=#{@tag.id}&tries=5")
      end
      
      it "should result in a success when tries is > 7" do
        get :clues, :id => 1234, :tag => @tag.id, :tries => 8
        response.should be_success
        response.should render_template("clues")
      end
    end
  end
    
  it "sets_last_accessed_time_on_each_request" do
    user = Generate.user!
    login_as user
    old_time = user.last_accessed_at = 1.minute.ago
    
    get :index
    user.reload
    assert_instance_of(ActiveSupport::TimeWithZone, user.last_accessed_at)
    assert(old_time < user.last_accessed_at)
  end
  
  it "mark_read" do
    assert_difference("Reading.count", 1) do
      feed_item = Generate.feed_item!
      
      login_as Generate.user!
      put :mark_read, :id => feed_item.id, :format => "js"
      assert_response :success
    end
  end
  
  it "mark_read_twice_only_creates_one_entry_and_doesnt_fail" do
    assert_difference("Reading.count", 1) do
      feed_item = Generate.feed_item!
      
      login_as Generate.user!
      put :mark_read, :id => feed_item.id, :format => "js"
      assert_response :success
      put :mark_read, :id => feed_item.id, :format => "js"
      assert_response :success
    end
  end
  
  it "mark_many_read" do
    feed_item1 = Generate.feed_item!
    feed_item2 = Generate.feed_item!
    feed_item3 = Generate.feed_item!
    feed_item4 = Generate.feed_item!
    
    user = Generate.user!
    user.readings.create!(:readable_type => "FeedItem", :readable_id => feed_item1.id)
    user.readings.create!(:readable_type => "FeedItem", :readable_id => feed_item2.id)
    assert_difference("Reading.count", 2) do
      login_as user
      put :mark_read, :format => "js"
      assert_response :success
    end
  end
  
  it "mark_unread" do
    feed_item = Generate.feed_item!

    user = Generate.user!
    user.readings.create!(:readable_type => "FeedItem", :readable_id => feed_item.id)
    assert_difference("Reading.count", -1) do
      login_as user
      put :mark_unread, :id => feed_item.id, :format => "js"
      assert_response :success
    end
  end
end
