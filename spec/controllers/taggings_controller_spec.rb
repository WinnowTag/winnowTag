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

describe TaggingsController do
  it "starts a transaction" do
    feed_item = Generate.feed_item!
    
    login_as Generate.user!
    
    tagging = mock_model(Tagging, :save => true)
    Tagging.stub!(:new).and_return(tagging)
    Tagging.should_receive(:transaction).with().and_yield
    
    post :create, :tagging => { :feed_item_id => feed_item.id, :tag => 'one' }
  end
  
  it "create_without_tag_doesnt_create_tagging" do
    feed_item = Generate.feed_item!
    
    login_as Generate.user!
    
    assert_no_difference("Tagging.count") do
      post :create, :tagging => { :feed_item_id => feed_item.id }
    end
  end
  
  it "create_with_blank_tag_doesnt_create_tagging" do
    feed_item = Generate.feed_item!
    
    login_as Generate.user!
    
    assert_no_difference("Tagging.count") do
      post :create, :tagging => { :feed_item_id => feed_item.id, :tag => '' }
    end
  end
  
  it "create_with_duplicate_tag_doesnt_create_tagging" do
    feed_item = Generate.feed_item!

    login_as Generate.user!
    
    assert_difference("Tagging.count") do
      post :create, :tagging => { :feed_item_id => feed_item.id, :tag => 'one' }
    end
    assert_no_difference("Tagging.count") do
      post :create, :tagging => { :feed_item_id => feed_item.id, :tag => 'one' }
    end
  end
  
  it "create_tagging_with_strength_zero" do
    user = Generate.user!
    tag = Generate.tag!(:user => user)
    feed_item = Generate.feed_item!

    login_as user
    
    Tagging.first(:conditions => { :user_id => user.id, :feed_item_id => feed_item.id, :tag_id => tag.id, :strength => 0 }).should be_nil
                
    assert_difference(user.taggings, :count) do                                                    
      post :create, :format => "json", :tagging => { :strength => 0, :feed_item_id => feed_item.id, :tag => tag.name }
    end
    
    Tagging.first(:conditions => { :user_id => user.id, :feed_item_id => feed_item.id, :tag_id => tag.id, :strength => 0 }).should_not be_nil
  end
      
  it "destroy_tagging_specified_by_taggable_and_tag_name_with_ajax" do
    user = Generate.user!
    tag = Generate.tag!(:user => user)
    feed_item = Generate.feed_item!
    tagging = feed_item.taggings.create!(:tag => tag, :user => user)

    login_as user
    delete :destroy, :format => "json", :tagging => { :feed_item_id => feed_item.id, :tag => tag.name }
    assert_template 'destroy'
    assert_raise(ActiveRecord::RecordNotFound) { Tagging.find(tagging.id) }
  end
  
  it "destroy_does_not_destroy_classifier_taggings" do
    user = Generate.user!
    tag = Generate.tag!(:user => user)
    feed_item = Generate.feed_item!
    tagging = feed_item.taggings.create!(:tag => tag, :user => user)
    tagging = feed_item.taggings.create!(:tag => tag, :user => user, :classifier_tagging => true)

    login_as user

    assert_equal 2, Tagging.count
    delete :destroy, :format => "json", :tagging => { :feed_item_id => feed_item.id, :tag => tag.name }
    assert_equal 1, Tagging.count
  end
end
