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

describe "Marking comments read" do
  before(:each) do
    user = Generate.user!
    @tag = Generate.tag!(:user => user)
    
    TagSubscription.create!(:user => user, :tag => @tag)
    
    Comment.create! :user => user, :tag => @tag, :body => "good one"
    
    login user
    page.open tags_path
    page.wait_for :wait_for => :ajax
  end
  
  it "marks comments read when exapanding tag" do
    comment_count = page.get_text("css=#tag_#{@tag.id} .unread_comments")
    comment_count.should == "1"
    
    page.click "css=#tag_#{@tag.id} .summary"
    page.wait_for :wait_for => :ajax
    
    comment_count = page.get_text("css=#tag_#{@tag.id} .unread_comments")
    comment_count.should == "0"
  end
end