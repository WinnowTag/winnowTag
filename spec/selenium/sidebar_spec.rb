# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe "sidebar" do
  fixtures :users

  before(:each) do
    login
    page.open feed_items_path
    page.wait_for :wait_for => :ajax
  end
  
  it "is open by default" do
    assert_visible "sidebar"
  end
  
  it "hides when the control bar is clicked" do
    assert_visible "sidebar"

    page.click "sidebar_control"
    assert_not_visible "sidebar"
    
    page.click "sidebar_control"
    assert_visible "sidebar"
  end
  
  it "opens when the control bar is clicked" do
    page.click "sidebar_control"
    assert_not_visible "sidebar"

    page.click "sidebar_control"
    assert_visible "sidebar"
  end

  it "remembers the sidebar is closed when the page is refreshed" do
    page.click "sidebar_control"
    assert_not_visible "sidebar"

    page.refresh
    page.wait_for :wait_for => :page
    page.wait_for :wait_for => :ajax
    
    assert_not_visible "sidebar"
    
    page.click "sidebar_control"
    assert_visible "sidebar"
  end

  it "remembers the sidebar is open when the page is refreshed" do
    page.click "sidebar_control"
    assert_not_visible "sidebar"

    page.click "sidebar_control"
    assert_visible "sidebar"

    page.refresh
    page.wait_for :wait_for => :page
    page.wait_for :wait_for => :ajax
    
    assert_visible "sidebar"
  end
end
