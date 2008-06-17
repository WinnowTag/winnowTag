# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe FoldersController do
  fixtures :users, :tags

  before(:each) do
    login_as(:quentin)
    mock_user_for_controller
    
    @folder = mock_model(Folder, :save => true)
    @folders = mock("folders", :create! => @folder)
    @user.stub!(:folders).and_return(@folders)

    @params = { "name" => "Tech" }
  end

  describe "#create" do
    def do_post
      post :create, :folder => @params
    end
    
    it "creates a new folder for the current user" do
      @folders.should_receive(:create!).with(@params).and_return(@folder)
      do_post
    end

    it "renders the js template" do
      do_post
      response.should render_template("create")
    end
  end

  describe "#update" do
    before(:each) do
      @folder = mock_model(Folder, :update_attributes! => nil, :name => "Tech")
      @folders.stub!(:find).and_return(@folder)
    end

    def do_put
      put :update, :id => 1, :folder => @params
    end
    
    it "finds a new folder for the current user" do
      @folders.should_receive(:find).with("1").and_return(@folder)
      do_put
    end
    
    it "updates a new folder for the current user" do
      @folder.should_receive(:update_attributes!).with(@params)
      do_put
    end
    
    it "renders the folder name" do
      do_put
      response.should have_text("Tech")
    end
  end

  describe "#destroy" do
    before(:each) do
      @folders.stub!(:destroy)
    end

    def do_delete
      delete :destroy, :id => 1
    end
    
    it "destroys a new folder for the current user" do
      @folders.should_receive(:destroy).with("1")
      do_delete
    end
    
    it "renders the js template" do
      do_delete
      response.should render_template("destroy")
    end
  end

  describe "#add_item" do
    before(:each) do
      @folder = mock_model(Folder, :save! => nil, :feed_ids => [], :tag_ids => [], :add_feed! => nil, :add_tag! => nil)
      @folders.stub!(:find).and_return(@folder)
      
      @feed = mock_model(Feed)
      Feed.stub!(:find).with("1").and_return(@feed)
      
      @tag = mock_model(Tag)
      Tag.stub!(:find).with("2").and_return(@tag)
    end

    def do_put(item_id)
      put :add_item, :id => 1, :item_id => item_id
    end
    
    it "adds a new feed to the folder" do
      @folder.should_receive(:add_feed!).with("1")
      do_put("feed_1")
    end

    it "find the feed for the view" do
      Feed.should_receive(:find).with("1").and_return(@feed)
      do_put("feed_1")
      assigns(:feed).should == @feed
    end

    it "adds a new tag to the folder" do
      @folder.should_receive(:add_tag!).with("2")
      do_put("tag_2")
    end

    it "find the tag for the view" do
      Tag.should_receive(:find).with("2").and_return(@tag)
      do_put("tag_2")
      assigns(:tag).should == @tag
    end
  end

  describe "#remove_item" do
    before(:each) do
      @folder = mock_model(Folder, :save! => nil, :feed_ids => [1,2], :tag_ids => [1,2])
      @folders.stub!(:find).and_return(@folder)
    end

    def do_put(item_id)
      put :remove_item, :id => 1, :item_id => item_id
    end
    
    it "adds a new feed to the folder" do
      @folder.should_receive(:remove_feed!).with("1")
      do_put("feed_1")
    end

    it "adds a new tag to the folder" do
      @folder.should_receive(:remove_tag!).with("2")
      do_put("tag_2")
    end
  end
end
