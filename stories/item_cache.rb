# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/helper'

steps_for(:item_cache) do
  Given("the feed entry at '$entry'") do |entry|
    @feed_entry = File.read(File.join('spec/fixtures', entry))
    @feed_count = Feed.count
  end
  
  Given("the item entry at '$entry'") do |entry|
    @item_entry = File.read(File.join('spec/fixtures', entry))
    @item_count = FeedItem.count
  end
  
  Given("a feed in the system") do
    @feed = Feed.new(:via => 'http://example.org/feed')
    @feed.id = rand(1000)
    @feed.save!
    @feed_id = @feed.id
  end
  
  Given("an item in the system") do    
    @item_id = rand(1000)
    @item = FeedItem.new(:link => "http://example.org/item/#{@item_id}")
    @item.id = @item_id
    @item.save!
    @item_count = FeedItem.count
  end
  
  Given("item $i in the system") do |i|
    @item_count = FeedItem.count
    @item_id = i
    begin
      @item = FeedItem.find(i)
    rescue ActiveRecord::RecordNotFound
      @item = FeedItem.new(:link => "http://example.org/item/#{i}")
      @item.id = i
      @item.save!
    end
  end
  
  When("I add the feed") do
    post item_cache_feeds_url, @feed_entry, 'Content-Type' => 'application/atom+xml;type=entry', 'Accept' => 'application/atom+xml'
    @feed_id = response.headers['Location'].split('/').last
  end
  
  When("I add the item to the feed") do
    post item_cache_feed_feed_items_url(Feed.find(@feed_id)), @item_entry, 'Content-Type' => 'application/atom+xml;type=entry', 'Accept' => 'application/atom+xml'
    @item_id = response.headers['Location'].split('/').last
  end
  
  When("I update the item") do
    put item_cache_feed_item_url(@item), @item_entry, 'Accept' => 'application/atom+xml', 'Content-Type' => 'application/atom+xml;type=entry'
  end
  
  When("I destroy the feed") do
    delete item_cache_feed_url(Feed.find(@feed_id)), 'Accept' => 'application/atom+xml'
  end
  
  When("I destroy the item") do
    delete item_cache_feed_item_url(FeedItem.find(@item_id)), 'Accept' => 'application/atom+xml'
  end
  
  Then("there is $n new feeds? in the system") do |n|
    Feed.count.should == (@feed_count + n.to_i)
  end
  
  Then("there is $n new items? in the system") do |n|
    FeedItem.count.should == (@item_count + n.to_i)
  end
  
  Then("the new item belongs to the feed") do
    FeedItem.find(@item_id).feed_id.should == @feed_id.to_i
  end
  
  Then("the item has been updated") do
    @item.attributes.should_not == FeedItem.find(@item_id).attributes    
  end
  
  Then("the item has not been updated") do
    @item.attributes.inspect.should == FeedItem.find(@item.id).attributes.inspect
  end
end

with_steps_for(:item_cache) do
  run_local_story 'item_cache', :type => RailsStory
end