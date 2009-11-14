# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe 'Classifier Controls' do
  before(:each) do
    @tag = Tag.create! :name => 'tag', :user_id => 1
    login
    open feed_items_path
    wait_for_ajax
  end
  
  # TODO: This do not work when the classifier is not actually running
  xit "should alert user when they try to classify tags with less than 6 positives" do
    click 'classification_button'
    wait_for_ajax
    get_confirmation.should == "You are about to classify 'tag' which has less than 6 positive examples. This might not work as well as you would expect.\nDo you want to proceed anyway?"
  end
  
  # TODO: This do not work when the classifier is not actually running
  xit "should use correct english when there is more than one tag" do
    Tag.create! :name => 'another tag', :user_id => 1
    click 'classification_button'
    wait_for_ajax
    get_confirmation.should == "You are about to classify 'another tag' and 'tag' which have less than 6 positive examples. This might not work as well as you would expect.\nDo you want to proceed anyway?"
  end
  
  # TODO: Sean - I do not have a classifier setup and running. 
  # I think we need to make the barrier of entry lower so all 
  # this would be easy to test
  xit "should be tested during actual classifier operation"
end