# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe "moderation panel" do
  include ActionView::Helpers::RecordIdentificationHelper

  fixtures :users, :feed_items, :feeds, :feed_item_contents
  
  before(:each) do
    Tagging.delete_all
    Tag.delete_all
    Reading.delete_all
    
    @positive_tag = Tag.create! :user_id => 1, :name => "positive tag"
    @negative_tag = Tag.create! :user_id => 1, :name => "negative tag"
    @classifier_tag = Tag.create! :user_id => 1, :name => "classifier tag"
    @positive_and_classifier_tag = Tag.create! :user_id => 1, :name => "positive and classifier tag"
    @negative_and_classifier_tag = Tag.create! :user_id => 1, :name => "negative and classifier tag"
    @unused_tag = Tag.create! :user_id => 1, :name => "unused tag"
    Tagging.create! :feed_item_id => 4, :user_id => 1, :tag_id => @positive_tag.id,                :strength => 1,    :classifier_tagging => false
    Tagging.create! :feed_item_id => 4, :user_id => 1, :tag_id => @negative_tag.id,                :strength => 0,    :classifier_tagging => false
    Tagging.create! :feed_item_id => 4, :user_id => 1, :tag_id => @classifier_tag.id,              :strength => 0.99, :classifier_tagging => true
    Tagging.create! :feed_item_id => 4, :user_id => 1, :tag_id => @positive_and_classifier_tag.id, :strength => 1,    :classifier_tagging => false
    Tagging.create! :feed_item_id => 4, :user_id => 1, :tag_id => @positive_and_classifier_tag.id, :strength => 0.99, :classifier_tagging => true
    Tagging.create! :feed_item_id => 4, :user_id => 1, :tag_id => @negative_and_classifier_tag.id, :strength => 0,    :classifier_tagging => false
    Tagging.create! :feed_item_id => 4, :user_id => 1, :tag_id => @negative_and_classifier_tag.id, :strength => 0.99, :classifier_tagging => true
    
    login
    page.open feed_items_path
    page.wait_for :wait_for => :ajax
  end
  
  it "can be shown by clicking the train link" do
    assert_not_visible "css=#feed_item_4 .moderation_panel"
    page.click "css=#feed_item_4 .train"
    assert_visible "css=#feed_item_4 .moderation_panel"
  end
  
  it "can be hidden by clicking the train link" do
    page.click "css=#feed_item_4 .train"

    assert_visible "css=#feed_item_4 .moderation_panel"
    page.click "css=#feed_item_4 .train"
    assert_not_visible "css=#feed_item_4 .moderation_panel"
  end
  
  it "does not open body when clicking the train link" do
    assert_not_visible "css=#feed_item_4 .body"
    page.click "css=#feed_item_4 .train"
    assert_not_visible "css=#feed_item_4 .body"
  end

  it "can be shown by clicking a tag in the tag list" do
    assert_not_visible "css=#feed_item_4 .moderation_panel"
    page.click "css=#feed_item_4 .tag_list .tag_control"
    assert_visible "css=#feed_item_4 .moderation_panel"
  end

  it "does not open body when clicking a tag in the tag list" do
    assert_not_visible "css=#feed_item_4 .body"
    page.click "css=#feed_item_4 .tag_list .tag_control"
    assert_not_visible "css=#feed_item_4 .body"
  end
  
  it "can be hidden by clicking the close link" do
    page.click "css=#feed_item_4 .train"
    page.wait_for :wait_for => :ajax

    assert_visible "css=#feed_item_4 .moderation_panel"
    page.click "css=#feed_item_4 .moderation_panel .close"
    assert_not_visible "css=#feed_item_4 .moderation_panel"
  end
  
  it "can change an unattached tagging to a positive tagging" do
    page.click "css=#feed_item_4 .train"
    page.wait_for :wait_for => :ajax
    
    dont_see_element "#feed_item_4 .moderation_panel .#{dom_id(@unused_tag)}.positive"
    page.click "css=#feed_item_4 .moderation_panel .#{dom_id(@unused_tag)} .name"
    see_element "#feed_item_4 .moderation_panel .#{dom_id(@unused_tag)}.positive"
  end
  
  it "can change a classifier tagging to a positive tagging" do
    page.click "css=#feed_item_4 .train"
    page.wait_for :wait_for => :ajax
    
    dont_see_element "#feed_item_4 .moderation_panel .#{dom_id(@classifier_tag)}.classifier.positive"
    page.click "css=#feed_item_4 .moderation_panel .#{dom_id(@classifier_tag)} .name"
    see_element "#feed_item_4 .moderation_panel .#{dom_id(@classifier_tag)}.classifier.positive"
  end
  
  it "can change a positive tagging to a negative tagging" do
    page.click "css=#feed_item_4 .train"
    page.wait_for :wait_for => :ajax
    
    dont_see_element "#feed_item_4 .moderation_panel .#{dom_id(@positive_tag)}.negative"
    page.click "css=#feed_item_4 .moderation_panel .#{dom_id(@positive_tag)} .name"
    see_element "#feed_item_4 .moderation_panel .#{dom_id(@positive_tag)}.negative"
  end
  
  it "can change a negative tagging to a classifier tagging" do
    page.click "css=#feed_item_4 .train"
    page.wait_for :wait_for => :ajax
    
    see_element "#feed_item_4 .moderation_panel .#{dom_id(@negative_and_classifier_tag)}.classifier.negative"
    page.click "css=#feed_item_4 .moderation_panel .#{dom_id(@negative_and_classifier_tag)} .name"
    dont_see_element "#feed_item_4 .moderation_panel .#{dom_id(@negative_and_classifier_tag)}.classifier.negative"
    see_element "#feed_item_4 .moderation_panel .#{dom_id(@negative_and_classifier_tag)}.classifier"
  end
  
  it "can change a negative tagging to an unattached tagging" do
    page.click "css=#feed_item_4 .train"
    page.wait_for :wait_for => :ajax
    page.choose_cancel_on_next_confirmation
    
    see_element "#feed_item_4 .moderation_panel .#{dom_id(@negative_tag)}.negative"
    page.click "css=#feed_item_4 .moderation_panel .#{dom_id(@negative_tag)} .name"
    dont_see_element "#feed_item_4 .moderation_panel .#{dom_id(@negative_tag)}.negative"
    see_element "#feed_item_4 .moderation_panel .#{dom_id(@negative_tag)}"

    page.confirmation.should include(@negative_tag.name)
  end

  it "can change an unattached tagging to a positive tagging through the text field" do
    page.click "css=#feed_item_4 .train"
    page.wait_for :wait_for => :ajax
    
    dont_see_element "#feed_item_4 .moderation_panel .#{dom_id(@unused_tag)}.positive"
    page.type "css=#feed_item_4 .moderation_panel input[type=text]", @unused_tag.name
    hit_enter "css=#feed_item_4 .moderation_panel input[type=text]"
    see_element "#feed_item_4 .moderation_panel .#{dom_id(@unused_tag)}.positive"
  end
  
  it "can change a classifer tagging to a positive tagging through the text field" do
    page.click "css=#feed_item_4 .train"
    page.wait_for :wait_for => :ajax
    
    dont_see_element "#feed_item_4 .moderation_panel .#{dom_id(@classifier_tag)}.positive"
    page.type "css=#feed_item_4 .moderation_panel input[type=text]", @classifier_tag.name
    hit_enter "css=#feed_item_4 .moderation_panel input[type=text]"
    see_element "#feed_item_4 .moderation_panel .#{dom_id(@classifier_tag)}.positive"
  end
  
  it "can change a negative tagging to a positive tagging through the text field" do
    page.click "css=#feed_item_4 .train"
    page.wait_for :wait_for => :ajax
    
    dont_see_element "#feed_item_4 .moderation_panel .#{dom_id(@negative_tag)}.positive"
    page.type "css=#feed_item_4 .moderation_panel input[type=text]", @negative_tag.name
    hit_enter "css=#feed_item_4 .moderation_panel input[type=text]"
    see_element "#feed_item_4 .moderation_panel .#{dom_id(@negative_tag)}.positive"
  end
  
  it "can create a new tag and add a positive tagging through the text field" do
    page.click "css=#feed_item_4 .train"
    page.wait_for :wait_for => :ajax
    
    dont_see_element "#feed_item_4 .moderation_panel .tag .name:contains(new tag)"
    page.type "css=#feed_item_4 .moderation_panel input[type=text]", "new tag"
    hit_enter "css=#feed_item_4 .moderation_panel input[type=text]"
    see_element "#feed_item_4 .moderation_panel .tag .name:contains(new tag)"
  end

  it "disables unmatched tags when typing" do
    page.click "css=#feed_item_4 .train"
    page.wait_for :wait_for => :ajax

    dont_see_element "#feed_item_4 .moderation_panel .tag.disabled .name:contains(positive tag)"
    dont_see_element "#feed_item_4 .moderation_panel .tag.disabled .name:contains(negative tag)"
    dont_see_element "#feed_item_4 .moderation_panel .tag.disabled .name:contains(^classifier tag)"
    dont_see_element "#feed_item_4 .moderation_panel .tag.disabled .name:contains(positive and classifier tag)"
    dont_see_element "#feed_item_4 .moderation_panel .tag.disabled .name:contains(negative and classifier tag)"
    dont_see_element "#feed_item_4 .moderation_panel .tag.disabled .name:contains(unused tag)"
    page.type_keys "css=#feed_item_4 .moderation_panel input[type=text]", "pos"
    dont_see_element "#feed_item_4 .moderation_panel .tag.disbaled .name:contains(positive tag)"
         see_element "#feed_item_4 .moderation_panel .tag.disabled .name:contains(negative tag)"
         see_element "#feed_item_4 .moderation_panel .tag.disabled .name:contains(^classifier tag)"
    dont_see_element "#feed_item_4 .moderation_panel .tag.disabled .name:contains(positive and classifier tag)"
         see_element "#feed_item_4 .moderation_panel .tag.disabled .name:contains(negative and classifier tag)"
         see_element "#feed_item_4 .moderation_panel .tag.disabled .name:contains(unused tag)"
  end
  
  it "selects the first matched tag when typing" do
    page.click "css=#feed_item_4 .train"
    page.wait_for :wait_for => :ajax
    
    dont_see_element "#feed_item_4 .moderation_panel .tag.selected .name:contains(positive tag)"
    dont_see_element "#feed_item_4 .moderation_panel .tag.selected .name:contains(negative tag)"
    dont_see_element "#feed_item_4 .moderation_panel .tag.selected .name:contains(^classifier tag)"
    dont_see_element "#feed_item_4 .moderation_panel .tag.selected .name:contains(positive and classifier tag)"
    dont_see_element "#feed_item_4 .moderation_panel .tag.selected .name:contains(negative and classifier tag)"
    dont_see_element "#feed_item_4 .moderation_panel .tag.selected .name:contains(unused tag)"
    page.type_keys "css=#feed_item_4 .moderation_panel input[type=text]", "pos"
    dont_see_element "#feed_item_4 .moderation_panel .tag.selected .name:contains(positive tag)"
    dont_see_element "#feed_item_4 .moderation_panel .tag.selected .name:contains(negative tag)"
    dont_see_element "#feed_item_4 .moderation_panel .tag.selected .name:contains(^classifier tag)"
         see_element "#feed_item_4 .moderation_panel .tag.selected .name:contains(positive and classifier tag)"
    dont_see_element "#feed_item_4 .moderation_panel .tag.selected .name:contains(negative and classifier tag)"
    dont_see_element "#feed_item_4 .moderation_panel .tag.selected .name:contains(unused tag)"
  end
  
  it "uses the selected tag when submitting the form" do
    page.click "css=#feed_item_4 .train"
    page.wait_for :wait_for => :ajax
    
    dont_see_element "#feed_item_4 .moderation_panel .#{dom_id(@classifier_tag)}.positive"
    dont_see_element "#feed_item_4 .moderation_panel .#{dom_id(@classifier_tag)}.selected"
    page.type_keys "css=#feed_item_4 .moderation_panel input[type=text]", "clas"
    see_element "#feed_item_4 .moderation_panel .#{dom_id(@classifier_tag)}.selected"
    hit_enter "css=#feed_item_4 .moderation_panel input[type=text]"
    see_element "#feed_item_4 .moderation_panel .#{dom_id(@classifier_tag)}.positive"    
  end
end
