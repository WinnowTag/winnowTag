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
  
  it "can add a positive taggig through the 'create a new tag' input" do
    dont_see_element "#tag_controls_feed_item_4 li"
    get_text("css=#open_tags_feed_item_4").should =~ /no tags/
    
    click "open_tags_feed_item_4"
    wait_for_ajax
    
    type "new_tag_field_feed_item_4", "new tag"
    hit_enter "new_tag_field_feed_item_4"

    see_element "#tag_controls_feed_item_4 li.positive"
    get_text("tag_control_for_new tag_on_feed_item_4").should =~ /new tag/
    get_text("open_tags_feed_item_4").should =~ /new tag/
  end
  
  it "can add a positive tagging by clicking on an existing tag" do
    dont_see_element "#tag_controls_feed_item_4 li"
    get_text("css=#open_tags_feed_item_4").should =~ /no tags/
    
    click "open_tags_feed_item_4"
    wait_for_ajax
    
    click "unused_tag_control_for_existing tag_on_feed_item_4"

    see_element "#tag_controls_feed_item_4 li.positive"
    get_text("tag_control_for_existing tag_on_feed_item_4").should =~ /existing tag/
    get_text("open_tags_feed_item_4").should =~ /existing tag/
  end
  
  it "can change a positive tagging to a negative tagging" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 1, :user_id => 1, :classifier_tagging => false

    open feed_items_path
    wait_for_ajax
    click "open_tags_feed_item_4"
    wait_for_ajax
    
    see_element "li.positive[id='tag_control_for_existing tag_on_feed_item_4']"
    dont_see_element "li.negative[id='tag_control_for_existing tag_on_feed_item_4']"
    see_element "#open_tags_feed_item_4 .positive"
    dont_see_element "#open_tags_feed_item_4 .negative"
    
    click  "css=li[id='tag_control_for_existing tag_on_feed_item_4'] .remove"
    wait_for_ajax
    
    dont_see_element "li.positive[id='tag_control_for_existing tag_on_feed_item_4']"
    see_element "li.negative[id='tag_control_for_existing tag_on_feed_item_4']"
    dont_see_element "#open_tags_feed_item_4 .positive"
    see_element "#open_tags_feed_item_4 .negative"
  end
  
  it "can change a negative tagging to a positive tagging" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 0, :user_id => 1, :classifier_tagging => false

    open feed_items_path
    wait_for_ajax
    click "open_tags_feed_item_4"
    wait_for_ajax
    
    see_element "li.negative[id='tag_control_for_existing tag_on_feed_item_4']"
    dont_see_element "li.positive[id='tag_control_for_existing tag_on_feed_item_4']"
    see_element "#open_tags_feed_item_4 .negative"
    dont_see_element "#open_tags_feed_item_4 .positive"
    
    click  "css=li[id='tag_control_for_existing tag_on_feed_item_4'] .add"
    wait_for_ajax
    
    dont_see_element "li.negative[id='tag_control_for_existing tag_on_feed_item_4']"
    see_element "li.positive[id='tag_control_for_existing tag_on_feed_item_4']"
    dont_see_element "#open_tags_feed_item_4 .negative"
    see_element "#open_tags_feed_item_4 .positive"
  end
  
  it "can change a classifier tagging to a positive tagging" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 1, :user_id => 1, :classifier_tagging => true

    open feed_items_path
    wait_for_ajax
    click "open_tags_feed_item_4"
    wait_for_ajax
    
    see_element "li.classifier[id='tag_control_for_existing tag_on_feed_item_4']"
    dont_see_element "li.positive[id='tag_control_for_existing tag_on_feed_item_4']"
    see_element "#open_tags_feed_item_4 .classifier"
    dont_see_element "#open_tags_feed_item_4 .positive"
    
    click  "css=li[id='tag_control_for_existing tag_on_feed_item_4'] .add"
    wait_for_ajax
    
    see_element "li.classifier[id='tag_control_for_existing tag_on_feed_item_4']"
    see_element "li.positive[id='tag_control_for_existing tag_on_feed_item_4']"
    see_element "#open_tags_feed_item_4 .positive"
  end
  
  it "can change a classifier tagging to a negative tagging" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 1, :user_id => 1, :classifier_tagging => true

    open feed_items_path
    wait_for_ajax
    click "open_tags_feed_item_4"
    wait_for_ajax
    
    see_element "li.classifier[id='tag_control_for_existing tag_on_feed_item_4']"
    dont_see_element "li.negative[id='tag_control_for_existing tag_on_feed_item_4']"
    see_element "#open_tags_feed_item_4 .classifier"
    dont_see_element "#open_tags_feed_item_4 .negative"
    
    click  "css=li[id='tag_control_for_existing tag_on_feed_item_4'] .remove"
    wait_for_ajax
    
    see_element "li.classifier[id='tag_control_for_existing tag_on_feed_item_4']"
    see_element "li.negative[id='tag_control_for_existing tag_on_feed_item_4']"
    see_element "#open_tags_feed_item_4 .negative"
  end
end