# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

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
