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