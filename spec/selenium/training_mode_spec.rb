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

describe "Training mode" do
  before(:each) do
     @user = Generate.user!

     @tag = Generate.tag!(:user => @user, :name => "tag")
     @tag2 = Generate.tag!(:user => @user, :name => "tag2")
     
     @feed_item1 = Generate.feed_item!
     @feed_item2 = Generate.feed_item!
     @feed_item3 = Generate.feed_item!
     @feed_item4 = Generate.feed_item!

     login @user
     page.open feed_items_path
     page.wait_for :wait_for => :ajax
  end
   
  it "should be off by default" do
    page.get_eval("window.sidebar.isEditing()").should == "false"
    page.is_visible("sidebar_edit").should be_false
  end
  
  it "should be on when turned on" do
    page.click("sidebar_edit_toggle")
    page.wait_for :wait_for => :ajax
    page.get_eval("window.sidebar.isEditing()").should == "true"
    page.is_visible("sidebar_edit").should be_true
  end
  
  it "should reset the mode when the edit panel is hidden" do
    page.click("sidebar_edit_toggle")
    page.click("name_tag_#{@tag.id}")
    page.wait_for :wait_for => :ajax
    page.click("trained_checkbox")
    page.wait_for :wait_for => :ajax
    page.location.should match(/mode=trained/)
    page.click("sidebar_edit_toggle")
    page.wait_for :wait_for => :ajax
    page.location.should match(/mode=all/)
  end
  
  it "should reset the text filter when the edit panel is hidden" do 
    page.click("sidebar_edit_toggle")
    page.type "text_filter", "ruby"
    page.fire_event("text_filter_form", "submit")
    page.location.should match(/text_filter=ruby/)
    page.wait_for :wait_for => :ajax
    page.click("sidebar_edit_toggle")
    page.location.should_not match(/text_filter/)
  end
  
  it "should open an items moderation panel when training mode is active" do
    page.click("sidebar_edit_toggle")
    page.wait_for :wait_for => :ajax
    page.click "css=#feed_item_#{@feed_item1.id} .closed"
    page.wait_for :wait_for => :ajax
    assert_visible "css=#feed_item_#{@feed_item1.id} .body"
    assert_visible "css=#feed_item_#{@feed_item1.id} .moderation_panel"
  end
  
  it "should disable 'Show only examples' if 'see all items' is selected" do
    page.click("sidebar_edit_toggle")
    page.wait_for :wait_for => :ajax
    page.click("css=#name_tag_0")
    page.wait_for :wait_for => :ajax
    page.click("css=#trained_checkbox")
    page.element?("css=#trained_checkbox.selected").should be_false
  end
  
  it "should unset 'Show only examples' if 'see all items' is selected" do
    page.click("sidebar_edit_toggle")
    page.wait_for :wait_for => :ajax
    page.click("css=#name_tag_#{@tag.id}")
    page.wait_for :wait_for => :ajax
    page.click("css=#trained_checkbox")
    page.click("css=#name_tag_0")
    page.wait_for :wait_for => :ajax
    page.element?("css=#trained_checkbox.selected").should be_false
  end
  
  it "should unset 'Show only examples' if any tag is selected" do
    page.click("sidebar_edit_toggle")
    page.wait_for :wait_for => :ajax
    page.click("css=#name_tag_#{@tag2.id}")
    page.wait_for :wait_for => :ajax
    page.click("css=#trained_checkbox")
    page.wait_for :wait_for => :ajax
    page.click("css=#name_tag_#{@tag.id}")
    page.wait_for :wait_for => :ajax
    page.element?("css=#trained_checkbox.selected").should be_false
  end
  
  it "should enable 'Show only examples' if a tag is selected" do
    page.click("sidebar_edit_toggle")
    page.wait_for :wait_for => :ajax
    page.click("css=#name_tag_0")
    page.wait_for :wait_for => :ajax
    page.click("css=#name_tag_#{@tag.id}")
    page.wait_for :wait_for => :ajax
    page.element?("css=#trained_checkbox.disabled").should be_false
  end
end
