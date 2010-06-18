# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe "Tags" do
  before(:each) do
    @user = Generate.user!
    @tag1 = Generate.tag! :user => @user, :bias => 0
    @tag2 = Generate.tag! :bias => 1, :public => true
    @user.tag_subscriptions.create!(:tag => @tag2)

    login @user
    page.open tags_path
    page.wait_for :wait_for => :ajax
  end
    
  # These are disabled under IE because selenium sets the wrong button code.
  #
  # See http://jira.openqa.org/browse/SEL-714
  #
  it_unless_ie "cant_change_bias_of_subscribed_tag" do
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
  
  it_unless_ie "changing_bias" do
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
end

describe 'merging' do
  before(:each) do
    @user = Generate.user!
    @tag1 = Generate.tag! :user => @user, :bias => 0
    @tag2 = Generate.tag! :bias => 1, :public => true
    @user.tag_subscriptions.create!(:tag => @tag2)
    
    @other = Generate.tag!(:user => @user, :name => "test")
    
    # TODO: determine if this is still needed now that all models are
    # set up before a page is opened.
    #
    # In IE there seems to be a synching problem,
    # sometimes loading the tags page happens 
    # without the @other tag present, I don't know if
    # this is a case of the follow load being ignored
    # because the previous one was same or what, but putting
    # the sleep here always ensures that @other appears in 
    # the page.
    sleep(1)
    
    login @user
    page.open tags_path
    page.wait_for :wait_for => :ajax
  end

  # TODO: This is only disabled because the test is temperamental and frequently fails.
  xit "can merge two tags by changing their names" do
    page.click "name_tag_#{@other.id}"
    
    see_element("#name_tag_#{@other.id}-inplaceeditor")
    page.type "css=input.editor_field", @tag1.name
    page.key_down "css=input.editor_field", '\13' # enter
    page.wait_for :wait_for => :ajax
    page.confirmation
    page.wait_for :wait_for => :ajax
    page.wait_for :wait_for => :element, :element => "css=#name_tag_#{@tag1.id}", :timeout_in_seconds => 5
    dont_see_element "#name_tag_#{@other.id}"
  end
end

describe "Renaming tags" do
  
  before(:each) do
    user = Generate.user!
    @tag = Generate.tag! :user => user, :bias => 0
    
    @new_name = "#{@tag.name}-renamed"

    login user
    page.open tags_path
    page.wait_for :wait_for => :ajax
  end
  
  def rename_tag
    page.click "name_tag_#{@tag.id}"
    
    see_element("#name_tag_#{@tag.id}-inplaceeditor")
    page.type "css=input.editor_field", @new_name
    page.key_down "css=input.editor_field", '\13' # enter
    page.wait_for :wait_for => :ajax
    see_element "#name_tag_#{@tag.id}"
  end
  
  it "changes the name of the tag" do
    rename_tag
    @tag.reload
    @tag.name.should == @new_name
  end
  
  it "updates the tag name for the bias slider" do
    rename_tag
    text = page.get_text("css=#tag_#{@tag.id} .slider_control .name")
    text.should include(@new_name)
  end
  
  it "updates the tag name in the 'show items tagged with' link" do
    rename_tag
    text = page.get_text("css=#tag_#{@tag.id} .tagged .name")
    text.should include(@new_name)
  end
  
  it "updates the tag name in the 'show items trainded with' link" do
    rename_tag
    text = page.get_text("css=#tag_#{@tag.id} .trained .name")
    text.should include(@new_name)
  end
  
  it "updates the name in 'feed' link" do
    rename_tag
    @tag.reload
    text = page.get_attribute("css=#tag_#{@tag.id} .controls .feed@href")
    text.should =~ /#{url_for(:controller => "tags", :action => "show", :user => @tag.user_login, :tag_name => @tag.name, :format => "atom", :only_path => true)}$/
  end
  
end

describe "Renaming tags as an admin" do
  
  before(:each) do
    user = Generate.admin!
    @tag = Generate.tag! :user => user, :bias => 0
    
    @new_name = "#{@tag.name}-renamed"

    login user
    page.open tags_path
    page.wait_for :wait_for => :ajax
  end
  
  def rename_tag
    page.click "name_tag_#{@tag.id}"
    
    see_element("#name_tag_#{@tag.id}-inplaceeditor")
    page.type "css=input.editor_field", @new_name
    page.key_down "css=input.editor_field", '\13' # enter
    page.wait_for :wait_for => :ajax
    see_element "#name_tag_#{@tag.id}"
  end
  
  it "updates the name in the 'training feed' link" do
    rename_tag
    @tag.reload
    text = page.get_attribute("css=#tag_#{@tag.id} .controls .feed.training@href")
    text.should =~ /#{url_for(:controller => "tags", :action => "training", :user => @tag.user_login, :tag_name => @tag.name, :format => "atom", :only_path => true)}$/
  end
  
end
