# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../../spec_helper'

describe '/feeds/index' do  
  before(:each) do
    login_as(1)
    @feed = mock_model_with_dom_id(Feed, valid_feed_attributes)
    @feeds = [@feed]
    @feeds.should_receive(:page_count).and_return(1)
    assigns[:feeds] = @feeds
  end
  
  it "should show feed icon with link to feed url" do
    render '/feeds/index'
    response.should have_tag("a[href='#{@feed.url}'][class~='feed_icon']", 1, response.body)
  end
  
  it "should show feed title with link to feed page" do
    render '/feeds/index'
    response.should have_tag("a[href='/feeds/#{@feed.id}']", @feed.title)
  end
  
  it "should show home icon with link to feed link" do
    render '/feeds/index'
    response.should have_tag("a[href='#{@feed.link}'][class~='home_icon']", 1, response.body)
  end
  
  it "should not show home link if there is none" do
    @feed.should_receive(:link).and_return(nil)
    render '/feeds/index'
    response.should have_tag("span[class~='blank_icon']")
  end
end