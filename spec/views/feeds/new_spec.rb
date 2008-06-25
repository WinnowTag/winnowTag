# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe '/feeds/new' do
  before(:each) do
    @feed = mock_new_model(Remote::Feed, :url => nil)
    assigns[:feed] = @feed
  end
  
  it "should show form" do
    render '/feeds/new'
    response.should have_tag("form[action='/feeds']")
  end
  
  it "should have a url field" do
    render '/feeds/new'
    response.should have_tag("input[name = 'feed[url]']", 1, response.body)
  end
end