# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe "Login" do
  fixtures :users
  
  it "successful_login" do
    login
    assert_match feed_items_url, get_location
  end
  
  it "unsuccessful_login" do
    login "quentin", "wrong"
    assert_match login_url, get_location
    assert_equal "Invalid credentials. Please try again.", get_text("css=.warning .content")
  end
end