require File.dirname(__FILE__) + '/../spec_helper'

describe "moderation panel" do
  fixtures :users, :feed_items, :feeds, :feed_item_contents
  
  before(:each) do
    Tagging.delete_all
    Tag.delete_all
    
    @existing_tag = Tag.create! :user_id => 1, :name => "existing tag"
    
    login
    open feed_items_path
    wait_for_ajax
  end
  
  it "can be shown by clicking the add tag link" do
    assert_not_visible "new_tag_form_feed_item_4"
    click "add_tag_feed_item_4"
    wait_for_ajax 
    assert_visible "new_tag_form_feed_item_4"
  end
  
  it "can add a positive tagging through the 'create a new tag' input" do
    click "add_tag_feed_item_4"
    wait_for_ajax
    
    dont_see_element "#tag_controls_feed_item_4 li"

    type "new_tag_field_feed_item_4", "new tag"
    hit_enter "new_tag_field_feed_item_4"
    wait_for_effects
    
    see_element "#tag_controls_feed_item_4 li.positive"
    get_text("tag_control_for_new tag_on_feed_item_4").should =~ /new tag/
  end

  it "can add a positive tagging by clicking on an existing tag" do 
    click "add_tag_feed_item_4" 
    wait_for_ajax 
     
    dont_see_element "#tag_controls_feed_item_4 li" 
     
    click "unused_tag_control_for_existing tag_on_feed_item_4" 
 
    see_element "#tag_controls_feed_item_4 li.positive" 
    get_text("tag_control_for_existing tag_on_feed_item_4").should =~ /existing tag/ 
  end 
  
  it "can change a positive tagging to a negative tagging" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 1, :user_id => 1, :classifier_tagging => false

    open feed_items_path
    wait_for_ajax
    
    see_element "li.positive[id='tag_control_for_existing tag_on_feed_item_4']"
    dont_see_element "li.negative[id='tag_control_for_existing tag_on_feed_item_4']"
    
    click  "css=li[id='tag_control_for_existing tag_on_feed_item_4'] .remove"
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
    
    click  "css=li[id='tag_control_for_existing tag_on_feed_item_4'] .add"
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
    
    click  "css=li[id='tag_control_for_existing tag_on_feed_item_4'] .add"
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
    
    click  "css=li[id='tag_control_for_existing tag_on_feed_item_4'] .remove"
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
    
    click  "css=li[id='tag_control_for_existing tag_on_feed_item_4'] .add"
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
    
    click  "css=li[id='tag_control_for_existing tag_on_feed_item_4'] .remove"
    wait_for_ajax
    
    see_element "li.classifier[id='tag_control_for_existing tag_on_feed_item_4']"
    dont_see_element "li.negative[id='tag_control_for_existing tag_on_feed_item_4']"
  end
  
  it "can change a positive tagging to a nothing tagging" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 1, :user_id => 1, :classifier_tagging => false

    open feed_items_path
    wait_for_ajax
    
    see_element "li.positive[id='tag_control_for_existing tag_on_feed_item_4']"
    
    click  "css=li[id='tag_control_for_existing tag_on_feed_item_4'] .add"
    wait_for_ajax
    wait_for_effects
    
    dont_see_element "li[id='tag_control_for_existing tag_on_feed_item_4']"
  end
  
  it "can change a negative tagging to a nothing tagging" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 0, :user_id => 1, :classifier_tagging => false

    open feed_items_path
    wait_for_ajax
    
    see_element "li.negative[id='tag_control_for_existing tag_on_feed_item_4']"
    
    click  "css=li[id='tag_control_for_existing tag_on_feed_item_4'] .remove"
    wait_for_ajax
    wait_for_effects
    
    dont_see_element "li[id='tag_control_for_existing tag_on_feed_item_4']"
  end
end