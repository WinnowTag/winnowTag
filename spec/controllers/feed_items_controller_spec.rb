# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe FeedItemsController do
  fixtures :users, :feeds, :feed_items, :tags

  it "requires_login" do
    assert_requires_login {|c| c.get :index, {}}
  end

  it "index" do
    login_as :quentin
    get :index
    assert_response :success
    assert_template 'index'
  end
  
  it "index_with_ajax" do
    login_as(:quentin)
    get :index, :offset => '1', :limit => '1', :show_untagged => true, :format => "js"
    assert_response :success
    assert_equal 'text/javascript; charset=utf-8', @response.headers['type']
    assert_not_nil assigns(:feed_items)
    assert_nil assigns(:feeds)
    # TODO: Move this test to a view test
    # regex = /itemBrowser\.insertItem\("#{dom_id(assigns(:feed_items).first)}", 1/
    # assert @response.body =~ regex, "#{regex} does match #{@response.body}"
  end
    
  it "/description" do
    login_as(:quentin)
    get :description, :id => 1, :format => "js"
    assert_response :success
    # TODO: Move the view test
    # assert_rjs :replace_html, 'body_feed_item_1'
  end
  
  describe "/clues" do
    before(:each) do
      login_as(:quentin)
      @user = User.find(1)
      @tag = Tag(@user, 'tag')
      
      @http_response = mock('response')
      @http_response.stub!(:code).and_return("200")
      @http_response.stub!(:body).and_return([{'clue' => 'bar', 'prob' => 0.01}, {'clue' => 'foo', 'prob' => 0.99}].to_json)
      Remote::ClassifierResource.site = "http://classifier.host/classifier"
      url = Remote::ClassifierResource.site.to_s + "/clues?" +
              "tag=#{URI.escape('http://test.host/quentin/tags/tag/training.atom')}" +
              "&item=#{URI.escape('urn:peerworks.org:entry#1234')}"
      Net::HTTP.should_receive(:get_response).with(URI.parse(url)).and_return(@http_response)
    end
    
    it "should render the clues" do
      accept('text/javascript')
      get :clues, :id => 1234, :tag => @tag.id
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
    login_as(:quentin)
    user = User.find(users(:quentin).id)
    old_time = user.last_accessed_at = 1.minute.ago
    
    get :index
    assert_instance_of(ActiveSupport::TimeWithZone, User.find(users(:quentin).id).last_accessed_at)
    assert(old_time < User.find(users(:quentin).id).last_accessed_at)
  end
  
  it "mark_read" do
    assert_difference("ReadItem.count", 1) do
      login_as(:quentin)
      put :mark_read, :id => 1, :format => "js"
      assert_response :success
    end
  end
  
  it "mark_read_twice_only_creates_one_entry_and_doesnt_fail" do
    assert_difference("ReadItem.count", 1) do
      login_as(:quentin)
      put :mark_read, :id => 1, :format => "js"
      assert_response :success
      put :mark_read, :id => 1, :format => "js"
      assert_response :success
    end
  end
  
  it "mark_many_read" do
    users(:quentin).read_items.create(:feed_item_id => 1)
    users(:quentin).read_items.create(:feed_item_id => 2)
    assert_difference("ReadItem.count", 2) do
      login_as(:quentin)
      put :mark_read, :format => "js"
      assert_response :success
    end
  end
  
  it "mark_unread" do
    users(:quentin).read_items.create(:feed_item_id => 2)
    assert_difference("ReadItem.count", -1) do
      login_as(:quentin)
      put :mark_unread, :id => 2, :format => "js"
      assert_response :success
    end
  end
end
