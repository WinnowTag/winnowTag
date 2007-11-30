require File.dirname(__FILE__) + '/../test_helper'

class TagsPublicTest < Test::Unit::SeleniumTestCase
  include SeleniumHelper
  fixtures :users, :tags
  
  def setup
    login
    open public_tags_path
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
end
