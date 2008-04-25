require File.dirname(__FILE__) + '/../spec_helper'

describe "/feeds" do
  fixtures :feeds
  
  before(:each) do
    login
    open feeds_path
    wait_for_ajax
  end    
  
  # These test just make sure that the headers are correct.
  # Normally you would do this in a view test but since the
  # implementation uses "content_for", views tests won't work.
  it "should have an 'Add Feed' link on index" do
    see_element 'a[href="/feeds/new"]'
  end
  
  it "should have an 'Add Feed' link on feed's page" do
    feed = Feed.find(:first)
    click_and_wait "link_to_feed_#{feed.id}"
    see_element 'a[href="/feeds/new"]'
  end
  
  it "should show the search field on the index page" do
    see_element '#text_filter'
  end
  
  it "should hide the search field on a feed page" do
    feed = Feed.find(:first)
    click_and_wait "link_to_feed_#{feed.id}"
    dont_see_element '#text_filter'
  end
end
