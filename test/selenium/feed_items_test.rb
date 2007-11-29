require File.dirname(__FILE__) + '/../test_helper'

class FeedItemsTest < Test::Unit::SeleniumTestCase
  include SeleniumHelper
  fixtures :users, :views, :feed_items, :feeds, :unread_items

  def setup
    delete_cookie "show_sidebar", "/"
    login
    open feed_items_path
  end

  def test_mark_read_unread
    feed_item_1 = FeedItem.find(1)
    
    see_element "#feed_item_#{feed_item_1.id}.read"

    click "css=#feed_item_#{feed_item_1.id} .status a"
    see_element "#feed_item_#{feed_item_1.id}.unread"
    
    refresh_and_wait
    see_element "#feed_item_#{feed_item_1.id}.unread"

    click "css=#feed_item_#{feed_item_1.id} .status a"
    see_element "#feed_item_#{feed_item_1.id}.read"

    refresh_and_wait
    see_element "#feed_item_#{feed_item_1.id}.read"
  end
  
  def test_open_close_item
    feed_item = FeedItem.find(:first)

    assert_not_visible "open_feed_item_#{feed_item.id}"
    
    click "css=#feed_item_#{feed_item.id} .opener"
    assert_visible "open_feed_item_#{feed_item.id}"
    
    click "css=#feed_item_#{feed_item.id} .opener"
    assert_not_visible "open_feed_item_#{feed_item.id}"
  end
  
  def test_open_close_moderation_panel
    feed_item = FeedItem.find(:first)

    assert_not_visible "new_tag_form_feed_item_#{feed_item.id}"

    click "open_tags_feed_item_#{feed_item.id}"
    assert_visible "new_tag_form_feed_item_#{feed_item.id}"

    click "open_tags_feed_item_#{feed_item.id}"
    assert_not_visible "new_tag_form_feed_item_#{feed_item.id}"
  end
  
  def test_open_close_sidebar
    feed_item = FeedItem.find(:first)
    
    assert_not_visible "sidebar"
    
    click "sidebar_control"
    assert_visible "sidebar"
    
    refresh_and_wait
    assert_visible "sidebar"

    click "sidebar_control"
    assert_not_visible "sidebar"
    
    refresh_and_wait
    assert_not_visible "sidebar"
  end
  
  def test_opening_item_marks_it_read
    feed_item_1 = FeedItem.find(1)

    see_element "#feed_item_#{feed_item_1.id}.unread"

    click "css=#feed_item_#{feed_item_1.id} .opener"
    see_element "#feed_item_#{feed_item_1.id}.read"

    refresh_and_wait
    see_element "#feed_item_#{feed_item_1.id}.read"
  end
end
