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
    page.open tags_path
    page.wait_for :wait_for => :ajax
  end
  
  describe 'merging' do
    before(:each) do
      @other = Tag.create!(:user_id => 1, :name => 'other')
      page.open tags_path
      page.wait_for :wait_for => :ajax
    end
    
    it "can merge two tags by changing their names" do
      tag = Tag.find(1)
      page.click "name_tag_#{@other.id}"
      
      see_element("#name_tag_#{@other.id}-inplaceeditor")
      page.type "css=input.editor_field", tag.name
      page.key_down "css=input.editor_field", '\13' # enter
      page.wait_for :wait_for => :ajax
      page.confirmation
      page.wait_for :wait_for => :page
      dont_see_element "#name_tag_#{@other.id}"
    end
  end
  
  it "can change the name of a tag" do
    tag = Tag.find(1)
    new_name = "#{tag.name}-renamed"
    page.click "name_tag_#{tag.id}"
    
    see_element("#name_tag_#{tag.id}-inplaceeditor")
    page.type "css=input.editor_field", new_name
    page.key_down "css=input.editor_field", '\13' # enter
    page.wait_for :wait_for => :ajax
    see_element "#name_tag_#{tag.id}"
    tag.reload
    tag.name.should == new_name
  end
  
  it "cant_change_bias_of_subscribed_tag" do
    tag = Tag.find(2)
    initial_position = page.get_element_position_left "css=#tag_#{tag.id} .slider_handle"
    page.mouse_down "css=#tag_#{tag.id} .slider_handle"
    page.mouse_move_at "css=#tag_#{tag.id} .slider_handle", "30,0"
    page.mouse_up "css=#tag_#{tag.id} .slider_handle"
    assert_equal initial_position, page.get_element_position_left("css=#tag_#{tag.id} .slider_handle")
    page.refresh
    page.wait_for :wait_for => :page
    page.wait_for :wait_for => :ajax
    assert_equal initial_position, page.get_element_position_left("css=#tag_#{tag.id} .slider_handle")
  end
  
  it "changing_bias" do
    tag = Tag.find(1)
    page.click "css=#tag_#{tag.id} .summary"
    initial_position = page.get_element_position_left "css=#tag_#{tag.id} .slider_handle"
    page.mouse_down "css=#tag_#{tag.id} .slider_handle"
    page.mouse_move_at "css=#tag_#{tag.id} .slider_handle", "30,0"
    page.mouse_up "css=#tag_#{tag.id} .slider_handle"
    assert_not_equal initial_position, page.get_element_position_left("css=#tag_#{tag.id} .slider_handle")
    new_position = page.get_element_position_left "css=#tag_#{tag.id} .slider_handle"
    page.refresh
    page.wait_for :wait_for => :page
    page.wait_for :wait_for => :ajax
    page.click "css=#tag_#{tag.id} .summary"
    assert_equal new_position, page.get_element_position_left("css=#tag_#{tag.id} .slider_handle")
  end
  
  it "destroying_a_tag" do
    tag = Tag.find(1)
    see_element "#destroy_tag_#{tag.id}"
    page.click "destroy_tag_#{tag.id}"
    page.should be_confirmation
    page.confirmation
    page.wait_for :wait_for => :ajax
    dont_see_element "#destroy_tag_#{tag.id}"
  end
  
  it "marking_a_tag_public" do
    tag_1 = Tag.find(1)

    assert !page.is_checked("public_tag_#{tag_1.id}")
    page.click "public_tag_#{tag_1.id}"
    assert page.is_checked("public_tag_#{tag_1.id}")
    page.refresh
    page.wait_for :wait_for => :page
    page.wait_for :wait_for => :ajax
    assert page.is_checked("public_tag_#{tag_1.id}")

    page.click "public_tag_#{tag_1.id}"
    assert !page.is_checked("public_tag_#{tag_1.id}")
    page.refresh
    page.wait_for :wait_for => :page
    page.wait_for :wait_for => :ajax
    assert !page.is_checked("public_tag_#{tag_1.id}")
  end
end
