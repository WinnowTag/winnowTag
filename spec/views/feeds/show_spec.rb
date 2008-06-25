# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe '/feeds/show' do
  fixtures :users
  
  include DateHelper
  
  before(:each) do
    login_as(1)
    @user = User.find(1)
    User.should_receive(:find_by_id).with(1).and_return(@user)
    @user.stub!(:globally_excluded?).any_number_of_times.and_return(false)
    
    @feed = mock_model_with_dom_id(Feed, valid_feed_attributes(:created_on => Time.now, :feed_items_count => 23))
    @feed_items = mock('feed_items')
    @feed_items.stub!(:size).and_return(23)
    @feed.stub!(:feed_items).and_return(@feed_items)

    assigns[:feed] = @feed
  end
  
  it "should show the title of the feed" do
    render '/feeds/show'
    response.should have_text(/#{@feed.title}/)
  end
  
  it "should show the created on date" do
    render '/feeds/show'
    response.should have_tag('th', 'Created On')
    response.should have_tag('td', /\d+ \w+, \d+/)
  end
  
  it "should show the url of the feed as a feed icon link" do
    render '/feeds/show'
    response.should have_tag("a[href='#{@feed.via}'][class='feed_icon replace']")
  end
  
  it "should show the link of the feed as a home icon link" do
    render '/feeds/show'
    response.should have_tag("a[href='#{@feed.alternate}'][class='home_icon replace']")
  end
  
  it "should skip the link of the feed if it is blank" do 
    @feed.should_receive(:alternate).and_return(nil)
    render '/feeds/show'
    response.should_not have_tag("a[class='home_icon replace']")
  end
    
  it "should show the number of items" do 
    render '/feeds/show'
    response.should have_tag("span.item_count", "23")
  end
  
  it "should show globally exclude state as unchecked when set to false" do
    @user.stub!(:globally_excluded?).any_number_of_times.and_return(false)
    render '/feeds/show'
    response.should     have_tag("#globally_exclude_feed_#{@feed.id}")
    response.should_not have_tag("#globally_exclude_feed_#{@feed.id}[checked='checked']")
  end
  
  it "should show globally exclude state as checked when set to true" do
    @user.stub!(:globally_excluded?).any_number_of_times.and_return(true)
    render '/feeds/show'
    response.should have_tag("#globally_exclude_feed_#{@feed.id}[checked='checked']", true, response.body)
  end
end