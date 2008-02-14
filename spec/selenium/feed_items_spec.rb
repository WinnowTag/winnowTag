require File.dirname(__FILE__) + '/../spec_helper'

describe "FeedItemsTest" do
  fixtures :users, :feed_items, :feeds

  before(:each) do
    ReadItem.delete_all
    ReadItem.create! :user_id => 1, :feed_item_id => 2
    ReadItem.create! :user_id => 1, :feed_item_id => 3
    ReadItem.create! :user_id => 1, :feed_item_id => 4
    
    delete_cookie "show_sidebar", "/"
    login
    open feed_items_path
    wait_for_ajax
  end

  def test_mark_read_unread
    feed_item_1 = FeedItem.find(2)
        
    see_element "#feed_item_#{feed_item_1.id}.read"

    click "css=#feed_item_#{feed_item_1.id} .status a"
    see_element "#feed_item_#{feed_item_1.id}.unread"
    
    refresh_and_wait
    wait_for_ajax
    see_element "#feed_item_#{feed_item_1.id}.unread"

    click "css=#feed_item_#{feed_item_1.id} .status a"
    see_element "#feed_item_#{feed_item_1.id}.read"

    refresh_and_wait
    wait_for_ajax
    see_element "#feed_item_#{feed_item_1.id}.read"
  end
  
  def test_open_close_item
    feed_item = FeedItem.find(2)

    assert_not_visible "open_feed_item_#{feed_item.id}"
    
    click "css=#feed_item_#{feed_item.id} .opener"
    assert_visible "open_feed_item_#{feed_item.id}"
    
    click "css=#feed_item_#{feed_item.id} .opener"
    assert_not_visible "open_feed_item_#{feed_item.id}"
  end
  
  def test_opening_item_marks_it_read
    feed_item_1 = FeedItem.find(1)

    see_element "#feed_item_#{feed_item_1.id}.unread"

    click "css=#feed_item_#{feed_item_1.id} .opener"
    see_element "#feed_item_#{feed_item_1.id}.read"

    refresh_and_wait
    wait_for_ajax
    see_element "#feed_item_#{feed_item_1.id}.read"
  end
  
  def test_click_feed_title_takes_you_to_feed_page
    feed_item_1 = FeedItem.find(1)
    feed1 = feed_item_1.feed
    see_element "#feed_link_for_feed_item_#{feed_item_1.id}"
    click_and_wait "css=#feed_link_for_feed_item_#{feed_item_1.id}"
    assert_match feed_url(feed1), get_location
    see_element "#feed_1"
  end
end
