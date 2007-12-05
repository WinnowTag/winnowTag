require File.dirname(__FILE__) + '/../test_helper'

class TagsTest < Test::Unit::SeleniumTestCase
  fixtures :users, :tags, :tag_subscriptions, :view_tag_states
  
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
    get_confirmation
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
  
  def test_cant_mark_subscribed_tag_public
    tag_1 = Tag.find(1)
    tag_2 = Tag.find(2)

    assert_element_enabled "#public_tag_#{tag_1.id}"
    assert_element_disabled "#public_tag_#{tag_2.id}"

    assert is_checked("public_tag_#{tag_2.id}")
    click "public_tag_#{tag_2.id}"
    assert is_checked("public_tag_#{tag_2.id}")
  end
  
  def test_changing_exclude_view_state
    dont_see_element "#exclude_tag_1.selected"

    click "exclude_tag_1"
    see_element "#exclude_tag_1.selected"

    refresh_and_wait
    see_element "#exclude_tag_1.selected"

    click "exclude_tag_1"
    dont_see_element "#exclude_tag_1.selected"

    refresh_and_wait
    dont_see_element "#exclude_tag_1.selected"
  end
  
  def test_changing_include_view_state
    dont_see_element "#include_tag_1.selected"

    click "include_tag_1"
    see_element "#include_tag_1.selected"

    refresh_and_wait
    see_element "#include_tag_1.selected"

    click "include_tag_1"
    dont_see_element "#include_tag_1.selected"
    
    refresh_and_wait
    dont_see_element "#include_tag_1.selected"
  end
  
  def test_changing_exclude_view_state_for_subscribed_tag
    tag = Tag.find(2)

    dont_see_element "#exclude_tag_#{tag.id}.selected"

    click "exclude_tag_#{tag.id}"
    see_element "#exclude_tag_#{tag.id}.selected"

    refresh_and_wait
    see_element "#exclude_tag_#{tag.id}.selected"

    click "exclude_tag_#{tag.id}"
    dont_see_element "#exclude_tag_#{tag.id}.selected"

    refresh_and_wait
    dont_see_element "#exclude_tag_#{tag.id}.selected"
  end
  
  def test_changing_include_view_state_for_subscribed_tag
    tag = Tag.find(2)

    dont_see_element "#include_tag_#{tag.id}.selected"

    click "include_tag_#{tag.id}"
    see_element "#include_tag_#{tag.id}.selected"

    refresh_and_wait
    see_element "#include_tag_#{tag.id}.selected"

    click "include_tag_#{tag.id}"
    dont_see_element "#include_tag_#{tag.id}.selected"

    refresh_and_wait
    dont_see_element "#include_tag_#{tag.id}.selected"
  end
end
