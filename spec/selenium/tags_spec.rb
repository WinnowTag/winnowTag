require File.dirname(__FILE__) + '/../spec_helper'

describe "Tags" do
  fixtures :users, :tags
  
  before(:each) do
    TagSubscription.delete_all
    TagSubscription.create! :user_id => 1, :tag_id => 2
    
    login
    open tags_path
  end
  
  it "cant_change_bias_of_subscribed_tag" do
    initial_position = get_element_position_left "css=div.tag.public div.slider_handle"
    mouse_down "css=div.tag.public div.slider_handle"
    mouse_move_at "css=div.tag.public div.slider_handle", "30,0"
    mouse_up "css=div.tag.public div.slider_handle"
    assert_equal initial_position, get_element_position_left("css=div.tag.public div.slider_handle")
    refresh_and_wait
    assert_equal initial_position, get_element_position_left("css=div.tag.public div.slider_handle")
  end
  
  it "changing_bias" do
    initial_position = get_element_position_left "css=div.tag.private div.slider_handle"
    mouse_down "css=div.tag.private div.slider_handle"
    mouse_move_at "css=div.tag.private div.slider_handle", "30,0"
    mouse_up "css=div.tag.private div.slider_handle"
    assert_not_equal initial_position, get_element_position_left("css=div.tag.private div.slider_handle")
    new_position = get_element_position_left "css=div.tag.private div.slider_handle"
    refresh_and_wait
    assert_equal new_position, get_element_position_left("css=div.tag.private div.slider_handle")
  end
  
  it "can be unsubscribed by clicking the destroy link" do
    tag = Tag.find(2)
  
    see_element "#unsubscribe_tag_#{tag.id}"
    click "unsubscribe_tag_#{tag.id}"
    wait_for_ajax
    dont_see_element "#unsubscribe_tag_#{tag.id}"
  end

  it "destroying_a_tag" do
    tag = Tag.find(1)
    see_element "#destroy_tag_#{tag.id}"
    click "destroy_tag_#{tag.id}"
    assert is_confirmation_present
    get_confirmation
    wait_for_ajax
    dont_see_element "#destroy_tag_#{tag.id}"
  end
  
  it "marking_a_tag_public" do
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
  
  it "cant_mark_subscribed_tag_public" do
    tag_1 = Tag.find(1)
    tag_2 = Tag.find(2)

    assert_element_enabled "#public_tag_#{tag_1.id}"
    assert_element_disabled "#public_tag_#{tag_2.id}"

    assert is_checked("public_tag_#{tag_2.id}")
    click "public_tag_#{tag_2.id}"
    assert is_checked("public_tag_#{tag_2.id}")
  end
end
