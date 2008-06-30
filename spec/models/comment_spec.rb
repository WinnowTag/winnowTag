# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe Comment do
  describe "validations" do
    it "validates presence of user id" do
      Generate.comment.should validate(:user_id, [1], [nil])
    end

    it "validates presence of tag id" do
      Generate.comment.should validate(:tag_id, [1], [nil])
    end

    it "validates presence of body" do
      Generate.comment.should validate(:body, ["Example Body"], [nil, ""])
    end
  end
  
  describe "associations" do
    it "belongs to user" do
      Generate.comment.should belong_to(:user)
    end
    
    it "belongs to tag" do
      Generate.comment.should belong_to(:tag)
    end
  end
  
  describe ".find_for_user" do
    before(:each) do
      @tagger = User.create! valid_user_attributes
      @tag = Tag.create! :user_id => @tagger.id, :name => "tag"
      
      @commenter = User.create! valid_user_attributes
      @comment = @commenter.comments.create! :tag_id => @tag.id, :body => "comment"
    end

    it "admin can find tag" do
      admin = User.create! valid_user_attributes
      admin.has_role("admin")
      
      Comment.find_for_user(admin, @comment.id).should == @comment
    end

    it "commenter can find tag" do
      Comment.find_for_user(@commenter, @comment.id).should == @comment
    end

    it "tagger can find tag" do
      Comment.find_for_user(@tagger, @comment.id).should == @comment
    end

    it "noone else can find tag" do
      user = User.create! valid_user_attributes
      
      lambda {
        Comment.find_for_user(user, @comment.id)
      }.should raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
