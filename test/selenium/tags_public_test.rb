require File.dirname(__FILE__) + '/../test_helper'

class TagsPublicTest < Test::Unit::SeleniumTestCase
  fixtures :users, :tags
  
  def setup
    login
    open public_tags_path
    TagSubscription.delete_all
  end
  
  def test_subscribing_to_public_tag
    tag_1 = Tag.find(1)
    tag_2 = Tag.find(2)

    assert !is_checked("subscribe_tag_#{tag_2.id}")
    click "subscribe_tag_#{tag_2.id}"
    assert is_checked("subscribe_tag_#{tag_2.id}")
    refresh_and_wait
    assert is_checked("subscribe_tag_#{tag_2.id}")

    click "subscribe_tag_#{tag_2.id}"
    assert !is_checked("subscribe_tag_#{tag_2.id}")
    refresh_and_wait
    assert !is_checked("subscribe_tag_#{tag_2.id}")
  end
  
  def test_cant_subscribe_to_own_public_tag
    tag_1 = Tag.create! :user_id => 1, :name => "public_tag", :public => true
    refresh_and_wait
    tag_2 = Tag.find(2)

    assert_element_disabled "#subscribe_tag_#{tag_1.id}"
    assert_element_enabled "#subscribe_tag_#{tag_2.id}"

    assert !is_checked("subscribe_tag_#{tag_1.id}")
    click "subscribe_tag_#{tag_1.id}"
    assert !is_checked("subscribe_tag_#{tag_1.id}")
  end
end
