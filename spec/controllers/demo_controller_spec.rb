# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DemoController do
  
  #Delete these examples and add some real ones
  it "should use DemoController" do
    controller.should be_an_instance_of(DemoController)
  end

  describe "GET 'index'" do
    before(:each) do
      @user = Generate.user
      User.should_receive(:find_by_login).with("pw_demo").and_return(@user)
    end
    
    it "should set the user to the demo user" do
      get :index
      assigns[:user].should == @user
    end
    
    it "should be successful" do
      get 'index'
      response.should be_success
    end
  end
  
  describe "GET index.json" do
    before(:each) do
      @user = Generate.user
      User.should_receive(:find_by_login).with("pw_demo").and_return(@user)
    end
    
    it "should be successful" do
      FeedItem.should_receive(:find_with_filters).with(:user => @user, :offset => nil, :limit => 80, :tag_ids => nil).and_return([])
      get 'index', :format => 'json'
      response.should be_success
    end
    
    it "should pass offset through to find" do
      FeedItem.should_receive(:find_with_filters).with(:user => @user, :offset => "40", :limit => 80, :tag_ids => nil).and_return([])
      get 'index', :format => 'json', :offset => "40"
      response.should be_success
    end
    
    it "should not pass limit through to find" do
      FeedItem.should_receive(:find_with_filters).with(:user => @user, :offset => nil, :limit => 80, :tag_ids => nil).and_return([])
      get 'index', :format => 'json', :limit => "100"
      response.should be_success
    end
    
    it "should pass tag ids through to find" do
      FeedItem.should_receive(:find_with_filters).with(:user => @user, :offset => nil, :limit => 80, :tag_ids => "23").and_return([])
      get 'index', :format => 'json', :tag_ids => "23"
      response.should be_success  
    end
    
    it "should not pass feed ids through to find" do
      FeedItem.should_receive(:find_with_filters).with(:user => @user, :offset => nil, :limit => 80, :tag_ids => nil).and_return([])
      get 'index', :format => 'json', :feed_ids => "23"
      response.should be_success
    end
  end
end
