# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe "Tag without comments" do  
  before(:each) do
    user = Generate.user!
    @tag = Generate.tag!(:user => user)
    
    TagSubscription.create!(:user => user, :tag => @tag)
    
    login user
    page.open tags_path
    page.wait_for :wait_for => :ajax
  end
  
  it "shows 0 unread comments" do
    comment_count = page.get_text("css=#tag_#{@tag.id} .unread_comments")
    comment_count.should == "0"
  end
  
  it "shows 0 total comments" do
    comment_count = page.get_text("css=#tag_#{@tag.id} .total_comments")
    comment_count.should == "0"
  end  
end

describe "Tag with no unread comments" do
  before(:each) do
    user = Generate.user!
    @tag = Generate.tag!(:user => user)
    
    TagSubscription.create!(:user => user, :tag => @tag)
    
    comment = Comment.create! :user => user, :tag => @tag, :body => "good one"
    comment.read_by!(user)
    
    login user
    page.open tags_path
    page.wait_for :wait_for => :ajax
  end
  
  it "shows 0 unread comments" do
    comment_count = page.get_text("css=#tag_#{@tag.id} .unread_comments")
    comment_count.should == "0"
  end
  
  it "shows 1 total comments" do
    comment_count = page.get_text("css=#tag_#{@tag.id} .total_comments")
    comment_count.should == "1"
  end
end

describe "Tag with one unread comment" do
  before(:each) do
    user = Generate.user!
    @tag = Generate.tag!(:user => user)
    
    TagSubscription.create!(:user => user, :tag => @tag)
    
    Comment.create! :user => user, :tag => @tag, :body => "good one"
    
    login user
    page.open tags_path
    page.wait_for :wait_for => :ajax
  end
  
  it "shows 1 unread comment" do
    comment_count = page.get_text("css=#tag_#{@tag.id} .unread_comments")
    comment_count.should == "1"
  end
  
  it "shows 1 total comments" do
    comment_count = page.get_text("css=#tag_#{@tag.id} .total_comments")
    comment_count.should == "1"
  end
end