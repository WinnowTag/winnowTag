# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe "moderation panel" do
  include ActionView::Helpers::RecordIdentificationHelper

  before(:each) do
    user = Generate.user!
    @positive_tag = Generate.tag!(:user => user, :name => "positive tag")
    @negative_tag = Generate.tag!(:user => user, :name => "negative tag")
    @classifier_tag = Generate.tag!(:user => user, :name => "classifier tag")
    @positive_and_classifier_tag = Generate.tag!(:user => user, :name => "positive and classifier tag")
    @negative_and_classifier_tag = Generate.tag!(:user => user, :name => "negative and classifier tag")
    @unused_tag = Generate.tag!(:user => user, :name => "unused tag")
    
    @feed_item = Generate.feed_item!
    
    @feed_item.taggings.create!(:user => user, :tag => @positive_tag,                :strength => 1,    :classifier_tagging => false)
    @feed_item.taggings.create!(:user => user, :tag => @negative_tag,                :strength => 0,    :classifier_tagging => false)
    @feed_item.taggings.create!(:user => user, :tag => @classifier_tag,              :strength => 0.99, :classifier_tagging => true)
    @feed_item.taggings.create!(:user => user, :tag => @positive_and_classifier_tag, :strength => 1,    :classifier_tagging => false)
    @feed_item.taggings.create!(:user => user, :tag => @positive_and_classifier_tag, :strength => 0.99, :classifier_tagging => true)
    @feed_item.taggings.create!(:user => user, :tag => @negative_and_classifier_tag, :strength => 0,    :classifier_tagging => false)
    @feed_item.taggings.create!(:user => user, :tag => @negative_and_classifier_tag, :strength => 0.99, :classifier_tagging => true)
    
    login user
    page.open feed_items_path
    page.wait_for :wait_for => :ajax
    page.click("sidebar_edit_toggle")
    page.wait_for :wait_for => :ajax
    page.click "css=#feed_item_#{@feed_item.id} .closed"
    page.wait_for :wait_for => :ajax
  end
  
  it "can change an unattached tagging to a positive tagging" do
    dont_see_element "##{dom_id(@feed_item)} .moderation_panel .#{dom_id(@unused_tag)}.positive"
    page.click "css=##{dom_id(@feed_item)} .moderation_panel .#{dom_id(@unused_tag)} .name"
    see_element "##{dom_id(@feed_item)} .moderation_panel .#{dom_id(@unused_tag)}.positive"
  end
  
  it "can change a classifier tagging to a positive tagging" do
    dont_see_element "##{dom_id(@feed_item)} .moderation_panel .#{dom_id(@classifier_tag)}.classifier.positive"
    page.click "css=##{dom_id(@feed_item)} .moderation_panel .#{dom_id(@classifier_tag)} .name"
    see_element "##{dom_id(@feed_item)} .moderation_panel .#{dom_id(@classifier_tag)}.classifier.positive"
  end
  
  it "can change a positive tagging to a negative tagging" do
    dont_see_element "##{dom_id(@feed_item)} .moderation_panel .#{dom_id(@positive_tag)}.negative"
    page.click "css=##{dom_id(@feed_item)} .moderation_panel .#{dom_id(@positive_tag)} .name"
    see_element "##{dom_id(@feed_item)} .moderation_panel .#{dom_id(@positive_tag)}.negative"
  end
  
  it "can change a negative tagging to a classifier tagging" do
    see_element "##{dom_id(@feed_item)} .moderation_panel .#{dom_id(@negative_and_classifier_tag)}.classifier.negative"
    page.click "css=##{dom_id(@feed_item)} .moderation_panel .#{dom_id(@negative_and_classifier_tag)} .name"
    dont_see_element "##{dom_id(@feed_item)} .moderation_panel .#{dom_id(@negative_and_classifier_tag)}.classifier.negative"
    see_element "##{dom_id(@feed_item)} .moderation_panel .#{dom_id(@negative_and_classifier_tag)}.classifier"
  end
  
  it "can change a negative tagging to an unattached tagging" do
    page.choose_cancel_on_next_confirmation
    
    see_element "##{dom_id(@feed_item)} .moderation_panel .#{dom_id(@negative_tag)}.negative"
    page.click "css=##{dom_id(@feed_item)} .moderation_panel .#{dom_id(@negative_tag)} .name"
    page.wait_for :wait_for => :ajax
    page.confirmation.should include(@negative_tag.name)
    dont_see_element "##{dom_id(@feed_item)} .moderation_panel .#{dom_id(@negative_tag)}.negative"
    see_element "##{dom_id(@feed_item)} .moderation_panel .#{dom_id(@negative_tag)}"
  end
end
