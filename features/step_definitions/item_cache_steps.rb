# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
Given("the feed entry at '$entry'") do |entry|
  @feed_entry = File.read(File.join(RAILS_ROOT, 'spec/fixtures', entry))
  @feed_count = Feed.count
end

Given("the item entry at '$entry'") do |entry|
  @item_entry = File.read(File.join(RAILS_ROOT, 'spec/fixtures', entry))
  @item_count = FeedItem.count
end

Given("a feed in the system") do
  @feed = Generate.feed!(:via => 'http://example.org/feed')
  @feed.save!
  @feed_id = @feed.id
end

Given("an item in the system") do    
  @item = FeedItem.new(:link => "http://example.org/item/blah", :uri => "urn:uuid:item:#{rand(1000)}")
  @item.save!
  @item_count = FeedItem.count
end

Given("item $i in the system") do |i|
  @item_count = FeedItem.count
  @item_id = i
  
  unless @item = FeedItem.find_by_uri("urn:uuid:item#{i}")    
    @item = FeedItem.new(:link => "http://example.org/item/#{i}", :uri => 'urn:uuid:item1')
    @item.save!
  end
end

When("I add the feed") do
  post_with_hmac item_cache_feeds_url, @feed_entry, 'Content-Type' => 'application/atom+xml;type=entry', 'Accept' => 'application/atom+xml'
  @feed_id = response.headers['Location'].split('/').last
end

When("I add the item to the feed") do
  post_with_hmac item_cache_feed_feed_items_url(:feed_id => Feed.find(@feed_id).uri), @item_entry, 'Content-Type' => 'application/atom+xml;type=entry', 'Accept' => 'application/atom+xml'
  @item_id = response.headers['Location'].split('/').last
end

When("I update the item") do
  put_with_hmac item_cache_feed_item_url(:id => @item.uri), @item_entry, 'Accept' => 'application/atom+xml', 'Content-Type' => 'application/atom+xml;type=entry'
end

When("I destroy the feed") do
  delete_with_hmac item_cache_feed_url(:id => Feed.find(@feed_id).uri), {}, 'Accept' => 'application/atom+xml'
end

When("I destroy the item") do
  delete_with_hmac item_cache_feed_item_url(:id => @item.uri), {}, 'Accept' => 'application/atom+xml'
end

When("I submit invalid atom for an? $thing") do |thing|
  url = case thing
    when 'feed' then item_cache_feeds_url
    when 'item' then item_cache_feed_feed_items_url(Feed.find(@feed_id))
  end
  post_with_hmac url, "<?xml version='1.0' ?>\n<entry>bad&nbsp;entry</entry>\n", 'Content-Type' => 'application/atom+xml;type=entry', 'Accept' => 'application/atom+xml'
end

Then("there is $n new feeds? in the system") do |n|
  Feed.count.should == (@feed_count + n.to_i)
end

Then("there is $n new items? in the system") do |n|
  FeedItem.count.should == (@item_count + n.to_i)
end

Then("the new item belongs to the feed") do
  FeedItem.find_by_uri(CGI::unescape(@item_id)).feed_id.should == @feed_id.to_i
end

Then("the item has been updated") do
  @item.attributes.should_not == FeedItem.find(@item.id).attributes    
end

Then("the item has not been updated") do
  @item.attributes.inspect.should == FeedItem.find(@item.id).attributes.inspect
end

Then("the system should return a $code") do |code|
  response.should_not be_nil
  response.code.should == code
end
