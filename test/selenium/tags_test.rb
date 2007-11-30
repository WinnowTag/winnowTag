require File.dirname(__FILE__) + '/../test_helper'

class TagsTest < Test::Unit::SeleniumTestCase
  include SeleniumHelper
  fixtures :users, :tags, :tag_subscriptions
  
  def setup
    login
    open tags_path
  end
  
  def test_cant_change_bias_of_subscribed_tag
    initial_position = get_element_position_left "css=tr.subscribed_tag div.slider_handle"
    mouse_down "css=tr.subscribed_tag div.slider_handle"
    mouse_move_at "css=tr.subscribed_tag div.slider_handle", "30,0"
    mouse_up "css=tr.subscribed_tag div.slider_handle"
    assert_equal initial_position, get_element_position_left("css=tr.subscribed_tag div.slider_handle")
    refresh_and_wait
    assert_equal initial_position, get_element_position_left("css=tr.subscribed_tag div.slider_handle")
  end
  
  def test_changing_bias
    initial_position = get_element_position_left "css=div.slider_handle"
    mouse_down "css=div.slider_handle"
    mouse_move_at "css=div.slider_handle", "30,0"
    mouse_up "css=div.slider_handle"
    assert_not_equal initial_position, get_element_position_left("css=div.slider_handle")
    new_position = get_element_position_left "css=div.slider_handle"
    refresh_and_wait
    assert_equal new_position, get_element_position_left("css=div.slider_handle")
  end
  
  def test_unsubscribing_from_a_tag
    tag = Tag.find(2)

    see_element "#unsubscribe_tag_#{tag.id}"
    click_and_wait "unsubscribe_tag_#{tag.id}"
    dont_see_element "#unsubscribe_tag_#{tag.id}"
  end
  
  def test_destroying_a_tag
    tag = Tag.find(1)
    see_element "#destroy_tag_#{tag.id}"
    click_and_wait "destroy_tag_#{tag.id}"
    assert is_confirmation_present
    dont_see_element "#destroy_tag_#{tag.id}"
  end
  
  def test_marking_a_tag_public
    tag_1 = Tag.find(1)

    assert !is_checked("public_tag_#{tag_1.id}")
    click "public_tag_#{tag_1.id}"
    assert is_checked("public_tag_#{tag_1.id}")
    refresh_and_wait
    assert is_checked("public_tag_#{tag_1.id}")

    click "public_tag_#{tag_1.id}"
    assert !is_checked("public_tag_#{tag_1.id}")
    refresh_and_wait
    assert !is_checked("public_tag_#{tag_1.id}")
  end
end
