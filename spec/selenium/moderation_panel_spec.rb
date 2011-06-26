# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

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
