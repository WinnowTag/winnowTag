# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../spec_helper'

describe 'Classifier Controls' do
  before(:each) do
    Tag.delete_all
    @tag = Tag.create! :name => 'tag', :user_id => 1
    login
    open feed_items_path
    wait_for_ajax
  end
  
  it "should alert user when they try to classify tags with less than 6 positives" do
    click 'classification_button'
    wait_for_ajax
    assert_visible 'confirm'
    assert_visible 'classification_button'
    assert_match("You are about to classify 'tag' which has less than 6 positive examples. " +
                 "This might not work as well as you would expect.\nDo you want to proceed anyway?",
                  get_text('confirm'))
                  
    assert_visible 'confirm_yes'
    assert_visible 'confirm_no'
  end
  
  it "should use correct english when there is more than one tag" do
    Tag.create! :name => 'another tag', :user_id => 1
    click 'classification_button'
    wait_for_ajax
    assert_visible 'confirm'
    assert_match("You are about to classify 'another tag' and 'tag' which have less than 6 positive examples. ",
                  get_text('confirm'))
  end
  
  it "should close the confirmation when no is clicked" do
    click 'classification_button'
    wait_for_ajax
    assert_visible 'confirm_no'
    click 'confirm_no'
    assert_not_visible 'confirm'
  end
  
  it "should send the real request when Yes is clicked" do
    click 'classification_button'
    wait_for_ajax
    assert_visible 'confirm_yes'
    click 'confirm_yes' 
    wait_for_ajax
    assert_not_visible 'confirm'    
    # How to check that classification has actually started?
    # This only works when the classifier is down and isn't 
    # very illustrative of what should happen.
    assert_visible 'error'
  end
  
  it "should not trample the location.hash when confirm_yes is clicked (bug #661)" do
    click "name_tag_#{@tag.id}"
    location = get_location
    click 'classification_button'
    wait_for_ajax
    click 'confirm_yes'
    get_location.should == location
  end
  
  it "should not trample the location.hash when confirm_no is clicked (bug #661)" do
    click "name_tag_#{@tag.id}"
    location = get_location
    click 'classification_button'
    wait_for_ajax
    click 'confirm_no'
    get_location.should == location
  end
  
  xit "should be tested during actual classifier operation"
end