# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
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
    page.click("mode_trained")
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
  
  it "should disable 'show trained' if 'see all items' is selected" do 
    page.click("sidebar_edit_toggle")
    page.wait_for :wait_for => :ajax
    page.click("css=#name_tag_0")
    assert_visible "css=#mode_trained.disabled"
    
    page.click("css=#mode_trained")
    page.element?("css=#mode_trained.selected").should be_false
  end
  
  it "should unset 'show trained' if 'see all items' is selected" do
    page.click("sidebar_edit_toggle")
    page.wait_for :wait_for => :ajax
    page.click("css=#name_tag_#{@tag.id}")
    page.wait_for :wait_for => :ajax
    page.click("css=#mode_trained")
    page.click("css=#name_tag_0")
    page.wait_for :wait_for => :ajax
    assert_visible("css=#mode_all.selected")
    page.element?("css=#mode_trained.selected").should be_false
  end
  
  it "should unset 'show trained' if any tag is selected" do
    page.click("sidebar_edit_toggle")
    page.wait_for :wait_for => :ajax
    page.click("css=#name_tag_#{@tag2.id}")
    page.wait_for :wait_for => :ajax
    page.click("css=#mode_trained")
    page.wait_for :wait_for => :ajax
    page.click("css=#name_tag_#{@tag.id}")
    page.wait_for :wait_for => :ajax
    assert_visible("css=#mode_all.selected")
    page.element?("css=#mode_trained.selected").should be_false
  end
  
  it "should enable 'show trained' if a tag is selected" do
    page.click("sidebar_edit_toggle")
    page.wait_for :wait_for => :ajax
    page.click("css=#name_tag_0")
    page.wait_for :wait_for => :ajax
    page.click("css=#name_tag_#{@tag.id}")
    page.wait_for :wait_for => :ajax
    page.element?("css=#mode_trained.disabled").should be_false
  end
end
