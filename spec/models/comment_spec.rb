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
      tagger = Generate.user!
      tag = Generate.tag!(:user => tagger, :name => "tag")
      commenter = Generate.user!
      comment = commenter.comments.create! :tag => tag, :body => "comment"
      
      lambda {
        comment.read_by!(tagger)
        comment.read_by!(tagger)
      }.should change(Reading, :count).by(1)
    end
    
  end
end
