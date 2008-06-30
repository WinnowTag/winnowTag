# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe "Tags" do
  fixtures :users, :tags
  
  before(:each) do
    TagSubscription.delete_all
    TagSubscription.create! :user_id => 1, :tag_id => 2
    
    login
    open tags_path
    wait_for_ajax
  end
  
  describe 'merging' do
    before(:each) do
      @other = Tag.create!(:user_id => 1, :name => 'other')
      open tags_path
      wait_for_ajax
    end
    
    it "can merge two tags by changing their names" do
      tag = Tag.find(1)
      click "name_tag_#{@other.id}"
      
      see_element("#name_tag_#{@other.id}-inplaceeditor")
      type "css=input.editor_field", tag.name
      hit_enter "css=input.editor_field"
      wait_for_ajax
      get_confirmation
      wait_for_page_to_load(30000)
      dont_see_element "#name_tag_#{@other.id}"
    end
  end
  
  it "can change the name of a tag" do
    tag = Tag.find(1)
    new_name = "#{tag.name}-renamed"
    click "name_tag_#{tag.id}"
    
    see_element("#name_tag_#{tag.id}-inplaceeditor")
    type "css=input.editor_field", new_name
    hit_enter "css=input.editor_field"
    wait_for_ajax
    see_element "#name_tag_#{tag.id}"
    tag.reload
    tag.name.should == new_name
  end
  
  it "cant_change_bias_of_subscribed_tag" do
    tag = Tag.find(2)
    initial_position = get_element_position_left "css=#tag_#{tag.id} .slider_handle"
    mouse_down "css=#tag_#{tag.id} .slider_handle"
    mouse_move_at "css=#tag_#{tag.id} .slider_handle", "30,0"
    mouse_up "css=#tag_#{tag.id} .slider_handle"
    assert_equal initial_position, get_element_position_left("css=#tag_#{tag.id} .slider_handle")
    refresh_and_wait
    wait_for_ajax
    assert_equal initial_position, get_element_position_left("css=#tag_#{tag.id} .slider_handle")
  end
  
  it "changing_bias" do
    tag = Tag.find(1)
    click "css=#tag_#{tag.id} .summary"
    initial_position = get_element_position_left "css=#tag_#{tag.id} .slider_handle"
    mouse_down "css=#tag_#{tag.id} .slider_handle"
    mouse_move_at "css=#tag_#{tag.id} .slider_handle", "30,0"
    mouse_up "css=#tag_#{tag.id} .slider_handle"
    assert_not_equal initial_position, get_element_position_left("css=#tag_#{tag.id} .slider_handle")
    new_position = get_element_position_left "css=#tag_#{tag.id} .slider_handle"
    refresh_and_wait
    wait_for_ajax
    click "css=#tag_#{tag.id} .summary"
    assert_equal new_position, get_element_position_left("css=#tag_#{tag.id} .slider_handle")
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
    wait_for_ajax
    assert is_checked("public_tag_#{tag_1.id}")

    click "public_tag_#{tag_1.id}"
    assert !is_checked("public_tag_#{tag_1.id}")
    refresh_and_wait
    wait_for_ajax
    assert !is_checked("public_tag_#{tag_1.id}")
  end
  
end
