require File.dirname(__FILE__) + '/../spec_helper'

describe "/feeds" do
  fixtures :feeds
  
  before(:each) do
    login
    open feeds_path
  end    
  
  it "should have an 'Add Feed' link on index" do
    see_element 'a[href="/feeds/new"]'
  end
  
  it "should have an 'Add Feed' link on feed's page" do
    feed = Feed.find(:first)
    click_and_wait "link_to_feed_#{feed.id}"
    see_element 'a[href="/feeds/new"]'
  end
end
