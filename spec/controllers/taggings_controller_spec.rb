# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
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
  
  it "create updates the tag to show in sidebar" do
    user = Generate.user!
    tag = Generate.tag!(:user => user, :show_in_sidebar => false)
    feed_item = Generate.feed_item!

    login_as user

    post :create, :format => "json", :tagging => { :strength => 1, :feed_item_id => feed_item.id, :tag => tag.name }

    tag.reload
    tag.show_in_sidebar?.should be_true
  end
      
  it "destroy_tagging_specified_by_taggable_and_tag_name_with_ajax" do
    user = Generate.user!
    tag = Generate.tag!(:user => user, :show_in_sidebar => false)
    feed_item = Generate.feed_item!
    tagging = feed_item.taggings.create!(:tag => tag, :user => user)

    login_as user
    delete :destroy, :format => "json", :tagging => { :feed_item_id => feed_item.id, :tag => tag.name }
    assert_template 'destroy'
    assert_raise(ActiveRecord::RecordNotFound) { Tagging.find(tagging.id) }
  end
  
  it "destroy_does_not_destroy_classifier_taggings" do
    user = Generate.user!
    tag = Generate.tag!(:user => user, :show_in_sidebar => false)
    feed_item = Generate.feed_item!
    tagging = feed_item.taggings.create!(:tag => tag, :user => user)
    tagging = feed_item.taggings.create!(:tag => tag, :user => user, :classifier_tagging => true)

    login_as user

    assert_equal 2, Tagging.count
    delete :destroy, :format => "json", :tagging => { :feed_item_id => feed_item.id, :tag => tag.name }
    assert_equal 1, Tagging.count
  end
end
