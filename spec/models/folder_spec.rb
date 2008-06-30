# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe Folder do
  describe "validations" do
    it "does not allow 2 folders to be named the same for same user" do
      Folder.create! :name => "demo", :user_id => 1
      folder = Folder.new :name => "demo", :user_id => 1
      folder.should_not be_valid
      folder.should have(1).errors_on(:name)
    end
  
    it "allows 2 folders to be named the same for different users" do
      Folder.create! :name => "demo", :user_id => 1
      folder = Folder.new :name => "demo", :user_id => 2
      folder.should be_valid
    end
  
    it "allows 2 folders to be named differently for the same user" do
      Folder.create! :name => "demo", :user_id => 1
      folder = Folder.new :name => "demo2", :user_id => 1
      folder.should be_valid
    end
  end
  
  describe "removing ad item from all of a users folders" do
    it "can remove a tag from all of a users folders" do
      user   = User.create! valid_user_attributes
      first  = user.folders.create! :name => "First",  :tag_ids => [1,2,3]
      second = user.folders.create! :name => "Second", :tag_ids => [2,1,3]
      third  = user.folders.create! :name => "Third",  :tag_ids => [1,3,2]
      fourth = user.folders.create! :name => "Forth",  :tag_ids => [1,3]

      Folder.remove_tag(user, 2)
  
      first.reload.tag_ids.should == [1,3]
      second.reload.tag_ids.should == [1,3]
      third.reload.tag_ids.should == [1,3]
      fourth.reload.tag_ids.should == [1,3]
    end

    it "can remove a feed from all of a users folders" do
      user   = User.create! valid_user_attributes
      first  = user.folders.create! :name => "First",  :feed_ids => [1,2,3]
      second = user.folders.create! :name => "Second", :feed_ids => [2,1,3]
      third  = user.folders.create! :name => "Third",  :feed_ids => [1,3,2]
      fourth = user.folders.create! :name => "Forth",  :feed_ids => [1,3]

      Folder.remove_feed(user, 2)
  
      first.reload.feed_ids.should == [1,3]
      second.reload.feed_ids.should == [1,3]
      third.reload.feed_ids.should == [1,3]
      fourth.reload.feed_ids.should == [1,3]
    end
  end
  
  describe "removing an item from a folder" do
    it "can remove a tag from a folder" do
      folder = Folder.create! :user_id => 1, :name => "thingy", :tag_ids => [1,2,3]
      folder.remove_tag!(2)
      folder.tag_ids.should == [1,3]
    end
    
    it "can remove a feed from a folder" do
      folder = Folder.create! :user_id => 1, :name => "thingy", :feed_ids => [1,2,3]
      folder.remove_feed!(2)
      folder.feed_ids.should == [1,3]
    end
  end
  
  describe "adding an item to a folder" do
    it "can add a tag to a folder" do
      folder = Folder.create! :user_id => 1, :name => "thingy", :tag_ids => [1,2]
      folder.add_tag!(3)
      folder.tag_ids.should == [1,2,3]
    end
    
    it "can add a feed to a folder" do
      folder = Folder.create! :user_id => 1, :name => "thingy", :feed_ids => [1,2]
      folder.add_feed!(3)
      folder.feed_ids.should == [1,2,3]
    end
  end
  
end