# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe "Training mode" do
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
   
  it "should be off by default" do
    page.get_eval("window.sidebar.isEditing()").should == "false"
    page.is_visible("sidebar_edit").should be_false
  end
  
  it "should be on when turned on" do
    page.click("sidebarEditToggle")
    page.get_eval("window.sidebar.isEditing()").should == "true"
    page.is_visible("sidebar_edit").should be_true
  end
  
  it "should reset the mode when the edit panel is hidden" do
    page.click("sidebarEditToggle")
    page.click("mode_trained")
    page.wait_for :wait_for => :ajax
    page.location.should match(/mode=trained/)
    page.click("sidebarEditToggle")
    page.wait_for :wait_for => :ajax
    page.location.should match(/mode=all/)
  end
end
