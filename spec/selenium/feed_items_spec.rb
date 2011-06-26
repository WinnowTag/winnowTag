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

describe "FeedItemsTest" do
  before(:each) do
    @user = Generate.user!
    
    @feed_item1 = Generate.feed_item!
    @feed_item2 = Generate.feed_item!
    @feed_item3 = Generate.feed_item!
    @feed_item4 = Generate.feed_item!
    
    Reading.create! :user_id => @user, :readable_type => "FeedItem", :readable => @feed_item2
    Reading.create! :user_id => @user, :readable_type => "FeedItem", :readable => @feed_item3
    Reading.create! :user_id => @user, :readable_type => "FeedItem", :readable => @feed_item4
    
    login @user
    page.open feed_items_path
    page.wait_for :wait_for => :ajax
  end

  it "mark_read_unread" do
    dont_see_element "#feed_item_#{@feed_item1.id}.read"

    page.click "css=#feed_item_#{@feed_item1.id} div.closed"
    page.wait_for :wait_for => :ajax
    see_element "#feed_item_#{@feed_item1.id}.read"

    # TODO: Make this work with mode=all
    # click "css=#feed_item_#{@feed_item1.id} .status a"
    # see_element "#feed_item_#{@feed_item1.id}.read"
    # 
    # refresh_and_wait
    # wait_for_ajax
    # see_element "#feed_item_#{@feed_item1.id}.read"
  end
  
  it "open_close_item" do
    assert_not_visible "css=#feed_item_#{@feed_item1.id} .body"
    
    page.click "css=#feed_item_#{@feed_item1.id} .closed"
    assert_visible "css=#feed_item_#{@feed_item1.id} .body"
    
    page.click "css=#feed_item_#{@feed_item1.id} .closed"
    assert_not_visible "css=#feed_item_#{@feed_item1.id} .body"
  end

  it "opening_item_marks_it_read" do
    dont_see_element "#feed_item_#{@feed_item1.id}.read"

    page.click "css=#feed_item_#{@feed_item1.id} .closed"
    see_element "#feed_item_#{@feed_item1.id}.read"
  end
  
  it "displays an empty message when there are no feed items" do
    FeedItem.delete_all
    sleep(1)
    page.open feed_items_path
    page.wait_for :wait_for => :ajax
  
    see_element "#content .empty"
  end
  
  it "does not display an empty message when there are feed items" do
    dont_see_element "#content .empty"
  end
end
