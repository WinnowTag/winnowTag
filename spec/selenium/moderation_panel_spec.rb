# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe "moderation panel" do
  fixtures :users, :feed_items, :feeds, :feed_item_contents
  
  before(:each) do
    Tagging.delete_all
    Tag.delete_all
    ReadItem.delete_all
    
    @existing_tag = Tag.create! :user_id => 1, :name => "existing tag"
    
    login
    open feed_items_path
    wait_for_ajax
  end
  
  it "can be shown by clicking the add tag link" do
    assert_not_visible "css=#feed_item_4 .new_tag_form"
    click "css=#feed_item_4 .add_tag"
    wait_for_ajax 
    assert_visible "css=#feed_item_4 .new_tag_form"
  end
  
  # 686 - selenium does not seem to have a way to query for the focused item
  # it "should focus the new tag field" do
  #   click "css=#feed_item_4 .add_tag"
  #   wait_for_ajax 
  #   see_element "#new_tag_field_feed_item_4:focus"
  # end
  
  # 686 - auto complete does not recognize typing
  # it "can add a positive tagging from a new tag through the 'create a new tag' input" do
  #   click "css=#feed_item_4 .add_tag"
  #   wait_for_ajax
  #   
  #   dont_see_element "li[id='tag_control_for_new tag_on_feed_item_4']"
  # 
  #   type "new_tag_field_feed_item_4", "new tag"
  #   click "css=#feed_item_4 .new_tag_form input[type=submit]"
  #   wait_for_effects
  #   
  #   see_element "li.positive[id='tag_control_for_new tag_on_feed_item_4']"
  #   get_text("tag_control_for_new tag_on_feed_item_4").should =~ /new tag/
  # end
  
  # 686 - auto complete does not recognize typing
  # it "can add a positive tagging from an existing tag through the 'create new tag' input" do 
  #   click "css=#feed_item_4 .add_tag" 
  #   wait_for_ajax 
  #    
  #   dont_see_element "li[id='tag_control_for_existing tag_on_feed_item_4']"
  #    
  #   type "new_tag_field_feed_item_4", "existing tag"
  #   click "css=#feed_item_4 .new_tag_form input[type=submit]"
  #   wait_for_effects
  # 
  #   see_element "li.positive[id='tag_control_for_existing tag_on_feed_item_4']"
  #   get_text("tag_control_for_existing tag_on_feed_item_4").should =~ /existing tag/
  # end

  it "selects the first choice in the auto complete list" do
    click "css=#feed_item_4 .add_tag" 
    wait_for_ajax 
  
    see_element "#feed_item_4 .new_tag_form .auto_complete li:first-child.selected"
  end
  
  it "uses the selected entry when clicking 'Add Tag'" do
    click "css=#feed_item_4 .add_tag"
    wait_for_ajax 
     
    dont_see_element "#tag_controls_feed_item_4 li"
     
    tag_name = get_text "css=#feed_item_4 .new_tag_form .auto_complete .selected"
    click "css=#feed_item_4 .new_tag_form input[type=submit]"
    wait_for_effects
  
    see_element "#tag_controls_feed_item_4 li[id='tag_control_for_#{tag_name}_on_feed_item_4']"
    get_text("tag_control_for_existing tag_on_feed_item_4").should =~ /existing tag/
  end

  # 686 - auto complete does not recognize hitting enter
  # it "uses the selected entry when hitting enter 'Add Tag'"
  
  it "can change a positive tagging to a negative tagging" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 1, :user_id => 1, :classifier_tagging => false

    open feed_items_path
    wait_for_ajax
    
    see_element "li.positive[id='tag_control_for_existing tag_on_feed_item_4']"
    dont_see_element "li.negative[id='tag_control_for_existing tag_on_feed_item_4']"
    
    click "css=div[id='tag_info_for_existing tag_on_feed_item_4'] .negative"
    wait_for_ajax
    
    dont_see_element "li.positive[id='tag_control_for_existing tag_on_feed_item_4']"
    see_element "li.negative[id='tag_control_for_existing tag_on_feed_item_4']"
  end
  
  it "can change a negative tagging to a positive tagging" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 0, :user_id => 1, :classifier_tagging => false

    open feed_items_path
    wait_for_ajax
    
    see_element "li.negative[id='tag_control_for_existing tag_on_feed_item_4']"
    dont_see_element "li.positive[id='tag_control_for_existing tag_on_feed_item_4']"
    
    click "css=div[id='tag_info_for_existing tag_on_feed_item_4'] .positive"
    wait_for_ajax
    
    dont_see_element "li.negative[id='tag_control_for_existing tag_on_feed_item_4']"
    see_element "li.positive[id='tag_control_for_existing tag_on_feed_item_4']"
  end
  
  it "can change a classifier tagging to a positive tagging" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 1, :user_id => 1, :classifier_tagging => true

    open feed_items_path
    wait_for_ajax
    
    see_element "li.classifier[id='tag_control_for_existing tag_on_feed_item_4']"
    dont_see_element "li.positive[id='tag_control_for_existing tag_on_feed_item_4']"
    
    click "css=div[id='tag_info_for_existing tag_on_feed_item_4'] .positive"
    wait_for_ajax
    
    see_element "li.classifier[id='tag_control_for_existing tag_on_feed_item_4']"
    see_element "li.positive[id='tag_control_for_existing tag_on_feed_item_4']"
  end
  
  it "can change a classifier tagging to a negative tagging" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 1, :user_id => 1, :classifier_tagging => true

    open feed_items_path
    wait_for_ajax
    
    see_element "li.classifier[id='tag_control_for_existing tag_on_feed_item_4']"
    dont_see_element "li.negative[id='tag_control_for_existing tag_on_feed_item_4']"
    
    click "css=div[id='tag_info_for_existing tag_on_feed_item_4'] .negative"
    wait_for_ajax
    
    see_element "li.classifier[id='tag_control_for_existing tag_on_feed_item_4']"
    see_element "li.negative[id='tag_control_for_existing tag_on_feed_item_4']"
  end
  
  it "can change a positive tagging to a classifier tagging" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 1, :user_id => 1, :classifier_tagging => true
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 1, :user_id => 1, :classifier_tagging => false

    open feed_items_path
    wait_for_ajax
    
    see_element "li.classifier[id='tag_control_for_existing tag_on_feed_item_4']"
    see_element "li.positive[id='tag_control_for_existing tag_on_feed_item_4']"
    
    click "css=div[id='tag_info_for_existing tag_on_feed_item_4'] .remove"
    wait_for_ajax
    
    see_element "li.classifier[id='tag_control_for_existing tag_on_feed_item_4']"
    dont_see_element "li.positive[id='tag_control_for_existing tag_on_feed_item_4']"
  end
  
  it "can change a negative tagging to a classifier tagging" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 1, :user_id => 1, :classifier_tagging => true
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 0, :user_id => 1, :classifier_tagging => false

    open feed_items_path
    wait_for_ajax
    
    see_element "li.classifier[id='tag_control_for_existing tag_on_feed_item_4']"
    see_element "li.negative[id='tag_control_for_existing tag_on_feed_item_4']"
    
    click "css=div[id='tag_info_for_existing tag_on_feed_item_4'] .remove"
    wait_for_ajax
    
    see_element "li.classifier[id='tag_control_for_existing tag_on_feed_item_4']"
    dont_see_element "li.negative[id='tag_control_for_existing tag_on_feed_item_4']"
  end
  
  it "can change a positive tagging to a nothing tagging" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 1, :user_id => 1, :classifier_tagging => false

    open feed_items_path
    wait_for_ajax
    
    see_element "li.positive[id='tag_control_for_existing tag_on_feed_item_4']"
    
    click "css=div[id='tag_info_for_existing tag_on_feed_item_4'] .remove"
    wait_for_ajax
    wait_for_effects
    
    dont_see_element "li[id='tag_control_for_existing tag_on_feed_item_4']"
  end
  
  it "can change a negative tagging to a nothing tagging" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 0, :user_id => 1, :classifier_tagging => false

    open feed_items_path
    wait_for_ajax
    
    see_element "li.negative[id='tag_control_for_existing tag_on_feed_item_4']"
    
    click "css=div[id='tag_info_for_existing tag_on_feed_item_4'] .remove"
    wait_for_ajax
    wait_for_effects
    
    dont_see_element "li[id='tag_control_for_existing tag_on_feed_item_4']"
  end
  
  it "open tag info does not open/close item" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 1, :user_id => 1, :classifier_tagging => false

    open feed_items_path
    wait_for_ajax
    
    assert_not_visible "css=#feed_item_4 .body"
    click "css=li[id='tag_control_for_existing tag_on_feed_item_4']"
    assert_not_visible "css=#feed_item_4 .body"
  end
  
  it "shows/hides tagging controls when clicking the tag" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 1, :user_id => 1, :classifier_tagging => true
  
    open feed_items_path
    wait_for_ajax
    
    assert_not_visible "css=div[id='tag_info_for_existing tag_on_feed_item_4']"
    click "css=li[id='tag_control_for_existing tag_on_feed_item_4']"
    assert_visible "css=div[id='tag_info_for_existing tag_on_feed_item_4']"
    click "css=li[id='tag_control_for_existing tag_on_feed_item_4']"
    assert_not_visible "css=div[id='tag_info_for_existing tag_on_feed_item_4']"
  end
end
