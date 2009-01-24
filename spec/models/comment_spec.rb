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
      @tagger = Generate.user!
      @tag = Generate.tag!(:user => @tagger)
      
      @commenter = Generate.user!
      @comment = @commenter.comments.create!(:tag => @tag, :body => "comment")
    end

    it "admin can find tag" do
      admin = Generate.admin!
      
      Comment.find_for_user(admin, @comment.id).should == @comment
    end

    it "commenter can find tag" do
      Comment.find_for_user(@commenter, @comment.id).should == @comment
    end

    it "tagger can find tag" do
      Comment.find_for_user(@tagger, @comment.id).should == @comment
    end

    it "noone else can find tag" do
      user = Generate.user!
      
      lambda {
        Comment.find_for_user(user, @comment.id)
      }.should raise_error(ActiveRecord::RecordNotFound)
    end
  end
  
  describe "marking read" do
    
    it "is marked as read only once per reader" do
      tagger = User.create! valid_user_attributes
      tag = tagger.tags.create! :name => "tag"
      commenter = User.create! valid_user_attributes
      comment = commenter.comments.create! :tag => tag, :body => "comment"
      
      lambda {
        comment.read_by!(tagger)
        comment.read_by!(tagger)
      }.should change(Reading, :count).by(1)
    end
    
  end
end
