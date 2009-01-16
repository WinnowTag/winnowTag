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
      user = Generate.user!
      tag1 = Generate.tag!(:user => user)
      tag2 = Generate.tag!(:user => user)
      first  = user.folders.create! :name => "First",  :tag_ids => [tag1.id, tag2.id]
      second = user.folders.create! :name => "Second", :tag_ids => [tag2.id, tag1.id]
      third = user.folders.create! :name => "Forth",  :tag_ids => [tag1.id]

      Folder.remove_tag(user, tag2.id)
  
      first.reload.tag_ids.should  == [tag1.id]
      second.reload.tag_ids.should == [tag1.id]
      third.reload.tag_ids.should  == [tag1.id]
    end

    it "can remove a feed from all of a users folders" do
      user = Generate.user!
      feed1 = Generate.feed!
      feed2 = Generate.feed!
      feed3 = Generate.feed!
      folder1 = user.folders.create! :name => "Folder 1", :feed_ids => [feed1.id, feed2.id, feed3.id]
      folder2 = user.folders.create! :name => "Folder 2", :feed_ids => [feed2.id, feed1.id, feed3.id]
      folder3 = user.folders.create! :name => "Folder 3", :feed_ids => [feed1.id, feed3.id, feed2.id]
      folder4 = user.folders.create! :name => "Folder 4", :feed_ids => [feed1.id, feed3.id]

      Folder.remove_feed(user, feed2.id)
  
      folder1.reload.feed_ids.should == [feed1.id, feed3.id]
      folder2.reload.feed_ids.should == [feed1.id, feed3.id]
      folder3.reload.feed_ids.should == [feed1.id, feed3.id]
      folder4.reload.feed_ids.should == [feed1.id, feed3.id]
    end
  end
end