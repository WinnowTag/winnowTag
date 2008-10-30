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
    page.location.should =~ /^#{feed_items_url}#.*$/
  end
  
  it "unsuccessful_login" do
    login "quentin", "wrong"
    page.location.should == login_url
    page.text_content("css=.warning .content").should == "Invalid credentials. Please try again."
  end
end