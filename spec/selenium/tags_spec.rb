# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe "Tags" do
  before(:each) do
    @user = Generate.user!
    @tag1 = Generate.tag! :user => @user, :bias => 0
    @tag2 = Generate.tag! :bias => 1, :public => true
    @user.tag_subscriptions.create!(:tag => @tag2)
    
    @tag_not_in_sidebar = Generate.tag! :user => @user, :show_in_sidebar => false

    login @user
    page.open tags_path
    page.wait_for :wait_for => :ajax
  end
  
  describe 'merging' do
    before(:each) do
      @other = Generate.tag!(:user => @user)
      page.open tags_path
      page.wait_for :wait_for => :ajax
    end
    
    it "can merge two tags by changing their names" do
      page.click "name_tag_#{@other.id}"
      
      see_element("#name_tag_#{@other.id}-inplaceeditor")
      page.type "css=input.editor_field", @tag1.name
      page.key_down "css=input.editor_field", '\13' # enter
      page.wait_for :wait_for => :ajax
      page.confirmation
      page.wait_for :wait_for => :page
      dont_see_element "#name_tag_#{@other.id}"
    end
  end

  it "can change the name of a tag" do
    new_name = "#{@tag1.name}-renamed"
    page.click "name_tag_#{@tag1.id}"
    
    see_element("#name_tag_#{@tag1.id}-inplaceeditor")
    page.type "css=input.editor_field", new_name
    page.key_down "css=input.editor_field", '\13' # enter
    page.wait_for :wait_for => :ajax
    see_element "#name_tag_#{@tag1.id}"
    @tag1.reload
    @tag1.name.should == new_name
  end
  
  it "cant_change_bias_of_subscribed_tag" do
    initial_position = page.get_element_position_left "css=#tag_#{@tag2.id} .slider_handle"
    page.mouse_down "css=#tag_#{@tag2.id} .slider_handle"
    page.mouse_move_at "css=#tag_#{@tag2.id} .slider_handle", "30,0"
    page.mouse_up "css=#tag_#{@tag2.id} .slider_handle"
    assert_equal initial_position, page.get_element_position_left("css=#tag_#{@tag2.id} .slider_handle")
    page.refresh
    page.wait_for :wait_for => :page
    page.wait_for :wait_for => :ajax
    assert_equal initial_position, page.get_element_position_left("css=#tag_#{@tag2.id} .slider_handle")
  end
  
  it "changing_bias" do
    page.click "css=#tag_#{@tag1.id} .summary"
    initial_position = page.get_element_position_left "css=#tag_#{@tag1.id} .slider_handle"
    page.mouse_down "css=#tag_#{@tag1.id} .slider_handle"
    page.mouse_move_at "css=#tag_#{@tag1.id} .slider_handle", "30,0"
    page.mouse_up "css=#tag_#{@tag1.id} .slider_handle"
    assert_not_equal initial_position, page.get_element_position_left("css=#tag_#{@tag1.id} .slider_handle")
    new_position = page.get_element_position_left "css=#tag_#{@tag1.id} .slider_handle"
    page.refresh
    page.wait_for :wait_for => :page
    page.wait_for :wait_for => :ajax
    page.click "css=#tag_#{@tag1.id} .summary"
    assert_equal new_position, page.get_element_position_left("css=#tag_#{@tag1.id} .slider_handle")
  end
  
  it "destroying_a_tag" do
    see_element "#destroy_tag_#{@tag1.id}"
    page.click "destroy_tag_#{@tag1.id}"
    page.should be_confirmation
    page.confirmation
    page.wait_for :wait_for => :ajax
    dont_see_element "#destroy_tag_#{@tag1.id}"
  end
  
  it "marking_a_tag_public" do
    assert !page.is_checked("public_tag_#{@tag1.id}")
    page.click "public_tag_#{@tag1.id}"
    assert page.is_checked("public_tag_#{@tag1.id}")
    page.refresh
    page.wait_for :wait_for => :page
    page.wait_for :wait_for => :ajax
    assert page.is_checked("public_tag_#{@tag1.id}")

    page.click "public_tag_#{@tag1.id}"
    assert !page.is_checked("public_tag_#{@tag1.id}")
    page.refresh
    page.wait_for :wait_for => :page
    page.wait_for :wait_for => :ajax
    assert !page.is_checked("public_tag_#{@tag1.id}")
  end

  xit "viewing items tagged with a specific tag also subscribes the user to that tag" do
    @user.sidebar_tags.should_not include(@tag_not_in_sidebar)

    link_text = I18n.t("winnow.tags.main.items_tagged_with", :tag => h(@tag_not_in_sidebar.name))
    page.click "link=#{link_text}"
    page.wait_for_page_to_load

    page.location.should =~ /^#{feed_items_url}#tag_ids=#{@tag_not_in_sidebar.id}$/
    @user.sidebar_tags(:reload).should include(@tag_not_in_sidebar)
  end

  xit "viewing items trained with a specific tag also subscribes the user to that tag" do
    @user.sidebar_tags.should_not include(@tag_not_in_sidebar)

    link_text = I18n.t("winnow.tags.main.items_trained_with", :tag => h(@tag_not_in_sidebar.name))
    page.click "link=#{link_text}"
    page.wait_for_page_to_load

    page.location.should =~ /^#{feed_items_url}#tag_ids=#{@tag_not_in_sidebar.id}&mode=trained$/
    @user.sidebar_tags(:reload).should include(@tag_not_in_sidebar)
  end
end
