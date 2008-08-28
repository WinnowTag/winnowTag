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
    fixtures :tags, :feeds
    
    it "can remove a tag from all of a users folders" do
      user   = User.create! valid_user_attributes
      first  = user.folders.create! :name => "First",  :tag_ids => [1,2]
      second = user.folders.create! :name => "Second", :tag_ids => [2,1]
      third = user.folders.create! :name => "Forth",  :tag_ids => [1]

      Folder.remove_tag(user, 2)
  
      first.reload.tag_ids.should == [1]
      second.reload.tag_ids.should == [1]
      third.reload.tag_ids.should == [1]
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
end