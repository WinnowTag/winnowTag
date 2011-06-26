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

describe "Demo" do
  before(:each) do
    @user = Generate.user!(:login => "pw_demo")
    @tag = @user.tags.create(:name => 'test')
    
    @items = [Generate.feed_item!, Generate.feed_item!, Generate.feed_item!]
    
    @tag.taggings.create!(:feed_item => @items.first, :user => @user)
    
    page.open "/"
    page.wait_for :wait_for => :page
    page.wait_for :wait_for => :ajax
  end
  
  it "should show the see all items pseudo-tag" do
    see_element("#tag_0")
    page.get_text("css=#tag_0").should == "See all items"
  end
  
  it "should hide the tag detail footer when show all items is set" do
    page.is_visible("css=#tag_detail_updating").should be_false
  end
  
  it "should show the tag" do
    see_element("#tag_#{@tag.id}")
  end
  
  it "should show all the items" do
    @items.each do |item|
      see_element("#feed_item_#{item.id}")
    end
  end
  
  it "should switch to tag filter when clicked" do
    page.click("css=#tag_#{@tag.id}")
    page.is_visible("css=#tag_#{@tag.id}.selected").should be_true
  end
  
  it "should show the tag_detail footer when a tag is selected" do
    page.click("css=#tag_#{@tag.id}")
    page.is_visible("css=#tag_detail_updating").should be_true
  end
  
  it "should set the tag details when a tag is selected" do
    page.click("css=#tag_#{@tag.id}")
    page.get_text("css=#updating_tag_name").should == "test"
    page.get_text("css=#updating_tag_count").should == "0"
  end
  
  it "should only show tagged items when the tag is selected" do 
    page.click("css=#tag_#{@tag.id}")
    page.wait_for :wait_for => :ajax
    page.is_visible("css=#feed_item_#{@items.first.id}").should be_true
    page.is_element_present("css=#feed_item_#{@items[1].id}").should be_false
    page.is_element_present("css=#feed_item_#{@items[1].id}").should be_false
  end
  
  it "should open items" do
    page.click("css=#feed_item_#{@items.first.id} .closed")
    page.wait_for :wait_for => :ajax
    assert_visible "css=#feed_item_#{@items.first.id} .body"
    page.get_text("css=#feed_item_#{@items.first.id} .body").should == "Author 25 \n Example Content"
  end
end
