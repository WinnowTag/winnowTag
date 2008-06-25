# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe "sidebar" do
  fixtures :users

  before(:each) do
    login
    open feed_items_path
    wait_for_ajax
  end
  
  it "is open by default" do
    assert_visible "sidebar"
  end
  
  it "hides when the control bar is clicked" do
    assert_visible "sidebar"

    click "sidebar_control"
    assert_not_visible "sidebar"
    
    click "sidebar_control"
    assert_visible "sidebar"
  end
  
  it "opens when the control bar is clicked" do
    click "sidebar_control"
    assert_not_visible "sidebar"

    click "sidebar_control"
    assert_visible "sidebar"
  end

  it "remembers the sidebar is closed when the page is refreshed" do
    click "sidebar_control"
    assert_not_visible "sidebar"

    refresh_and_wait
    wait_for_ajax
    
    assert_not_visible "sidebar"
    
    click "sidebar_control"
    assert_visible "sidebar"
  end

  it "remembers the sidebar is open when the page is refreshed" do
    click "sidebar_control"
    assert_not_visible "sidebar"

    click "sidebar_control"
    assert_visible "sidebar"

    refresh_and_wait
    wait_for_ajax
    
    assert_visible "sidebar"
  end
end
