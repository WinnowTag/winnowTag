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

describe "Feed Filtering" do
  before(:each) do
    @user = Generate.user!
    
    @feed1 = Generate.feed!
    @feed2 = Generate.feed!
    
    @feed_item1 = Generate.feed_item! :feed => @feed1
    @feed_item2 = Generate.feed_item! :feed => @feed1
    @feed_item3 = Generate.feed_item! :feed => @feed2
    @feed_item4 = Generate.feed_item! :feed => @feed2
    
    @tag = Generate.tag! :user => @user
    
    login @user
    page.open feed_items_path
    page.wait_for :wait_for => :ajax
  end

  it "should filter by the feed when clicked" do
    click_feed1
    page.location.should match(/feed_ids=#{@feed1.id}/)
    
    see_element("#feed_item_#{@feed_item1.id}")
    see_element("#feed_item_#{@feed_item2.id}")
    dont_see_element("#feed_item_#{@feed_item3.id}")
    dont_see_element("#feed_item_#{@feed_item4.id}")
  end
  
  it "should show the feed in the feed selection banner" do
    click_feed1
    
    see_element("#selectedFeed")
    page.get_text("filteredFeedTitle").should == @feed1.title
  end
  
  it "should cancel the filtering when the cancel button is pressed" do
    click_feed1
    
    page.click("css=#selectedFeed a")
    page.wait_for :wait_for => :ajax
    page.location.should_not match(/feed_ids=#{@feed1.id}/)
    
    see_element("#feed_item_#{@feed_item1.id}")
    see_element("#feed_item_#{@feed_item2.id}")
    see_element("#feed_item_#{@feed_item3.id}")
    see_element("#feed_item_#{@feed_item4.id}")
  end
  
  it "should cancel feed filtering when a tag is clicked" do
    click_feed1
    
    page.click("css=#tag_#{@tag.id} .name")
    page.wait_for :wait_for => :ajax
    page.location.should_not match(/feed_ids/)
  end
  
  def click_feed1
    page.click("css=#feed_item_#{@feed_item1.id} a.feed_title")
    page.wait_for :wait_for => :ajax
    page.click("css=#feed_#{@feed1.id} a.feed_filter_link")
    page.wait_for :wait_for => :ajax
  end
  
  def click_feed2
    page.click("css=#feed_item_#{@feed_item3.id} a.feed_title")
    page.wait_for :wait_for => :ajax
    page.click("css=#feed_#{@feed2.id} a.feed_filter_link")
    page.wait_for :wait_for => :ajax
  end
end
