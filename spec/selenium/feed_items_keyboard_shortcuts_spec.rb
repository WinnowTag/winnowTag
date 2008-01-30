require File.dirname(__FILE__) + '/../spec_helper'

describe "FeedItemsKeyboardShortcutsTest" do
  fixtures :users, :feed_items, :feeds

  before(:each) do
    login
    open feed_items_path
    sleep(3)
  end
  
  def test_change_item
    feed_item_2, feed_item_1 = FeedItem.find(3, 4)

    dont_see_element "#feed_item_#{feed_item_1.id}.selected"
    assert_not_visible "open_feed_item_#{feed_item_1.id}"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    assert_not_visible "open_feed_item_#{feed_item_2.id}"

    key_press "css=body", "j"
    see_element "#feed_item_#{feed_item_1.id}.selected"
    assert_visible "open_feed_item_#{feed_item_1.id}"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    assert_not_visible "open_feed_item_#{feed_item_2.id}"

    key_press "css=body", "j"
    dont_see_element "#feed_item_#{feed_item_1.id}.selected"
    assert_not_visible "open_feed_item_#{feed_item_1.id}"
    see_element "#feed_item_#{feed_item_2.id}.selected"
    assert_visible "open_feed_item_#{feed_item_2.id}"

    key_press "css=body", "k"
    see_element "#feed_item_#{feed_item_1.id}.selected"
    assert_visible "open_feed_item_#{feed_item_1.id}"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    assert_not_visible "open_feed_item_#{feed_item_2.id}"

    key_press "css=body", "k"
    see_element "#feed_item_#{feed_item_1.id}.selected"
    assert_visible "open_feed_item_#{feed_item_1.id}"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    assert_not_visible "open_feed_item_#{feed_item_2.id}"
  end
  
  def test_mark_read_unread
    feed_item_2, feed_item_1 = FeedItem.find(3, 4)

    dont_see_element "#feed_item_#{feed_item_1.id}.selected"
    see_element "#feed_item_#{feed_item_1.id}.read"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    see_element "#feed_item_#{feed_item_2.id}.read"

    key_press "css=body", "n"
    see_element "#feed_item_#{feed_item_1.id}.selected"
    see_element "#feed_item_#{feed_item_1.id}.read"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    see_element "#feed_item_#{feed_item_2.id}.read"

    key_press "css=body", "m"
    see_element "#feed_item_#{feed_item_1.id}.selected"
    see_element "#feed_item_#{feed_item_1.id}.unread"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    see_element "#feed_item_#{feed_item_2.id}.read"

    key_press "css=body", "m"
    see_element "#feed_item_#{feed_item_1.id}.selected"
    see_element "#feed_item_#{feed_item_1.id}.read"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    see_element "#feed_item_#{feed_item_2.id}.read"
  end
  
  def test_open_close_moderation_panel
    feed_item_2, feed_item_1 = FeedItem.find(3, 4)

    dont_see_element "#feed_item_#{feed_item_1.id}.selected"
    assert_not_visible "new_tag_form_feed_item_#{feed_item_1.id}"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    assert_not_visible "new_tag_form_feed_item_#{feed_item_2.id}"

    key_press "css=body", "n"
    see_element "#feed_item_#{feed_item_1.id}.selected"
    assert_not_visible "new_tag_form_feed_item_#{feed_item_1.id}"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    assert_not_visible "new_tag_form_feed_item_#{feed_item_2.id}"

    key_press "css=body", "t"
    see_element "#feed_item_#{feed_item_1.id}.selected"
    assert_visible "new_tag_form_feed_item_#{feed_item_1.id}"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    assert_not_visible "new_tag_form_feed_item_#{feed_item_2.id}"

    key_press "css=body", "t"
    see_element "#feed_item_#{feed_item_1.id}.selected"
    assert_not_visible "new_tag_form_feed_item_#{feed_item_1.id}"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    assert_not_visible "new_tag_form_feed_item_#{feed_item_2.id}"
  end
  
  def test_open_close_item
    feed_item_2, feed_item_1 = FeedItem.find(3, 4)

    dont_see_element "#feed_item_#{feed_item_1.id}.selected"
    assert_not_visible "open_feed_item_#{feed_item_1.id}"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    assert_not_visible "open_feed_item_#{feed_item_2.id}"

    key_press "css=body", "n"
    see_element "#feed_item_#{feed_item_1.id}.selected"
    assert_not_visible "open_feed_item_#{feed_item_1.id}"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    assert_not_visible "open_feed_item_#{feed_item_2.id}"

    key_press "css=body", "o"
    see_element "#feed_item_#{feed_item_1.id}.selected"
    assert_visible "open_feed_item_#{feed_item_1.id}"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    assert_not_visible "open_feed_item_#{feed_item_2.id}"

    key_press "css=body", "o"
    see_element "#feed_item_#{feed_item_1.id}.selected"
    assert_not_visible "open_feed_item_#{feed_item_1.id}"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
    assert_not_visible "open_feed_item_#{feed_item_2.id}"
  end
  
  def test_select_item
    feed_item_2, feed_item_1 = FeedItem.find(3, 4)

    dont_see_element "#feed_item_#{feed_item_1.id}.selected"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"

    key_press "css=body", "n"
    see_element "#feed_item_#{feed_item_1.id}.selected"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"

    key_press "css=body", "n"
    dont_see_element "#feed_item_#{feed_item_1.id}.selected"
    see_element "#feed_item_#{feed_item_2.id}.selected"

    key_press "css=body", "p"
    see_element "#feed_item_#{feed_item_1.id}.selected"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"

    key_press "css=body", "p"
    see_element "#feed_item_#{feed_item_1.id}.selected"
    dont_see_element "#feed_item_#{feed_item_2.id}.selected"
  end
end
