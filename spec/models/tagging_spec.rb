# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

Tag # auto-requires this class

describe Tagging do
  before(:each) do
    @feed_item = Generate.feed_item!
  end

  it "create_tagging" do
    user = Generate.user!
    feed_item = @feed_item
    tag = Tag(user, 'peerworks')
    tagging = Tagging.create(:user => user, :feed_item => feed_item, :tag => tag)
    assert_not_nil tagging
    assert_equal user, tagging.user
    assert_equal tag, tagging.tag
    assert_equal feed_item, tagging.feed_item
    
    tagging = Tagging.find(tagging.id)
    assert_not_nil tagging
    assert_equal user, tagging.user
    assert_equal tag, tagging.tag
    assert_equal feed_item, tagging.feed_item
    assert_equal 1.0, tagging.strength # default strength is 1.0
    
    # now make sure we can reach the tagging through each participant
    assert_not_nil tag.taggings.find(:first, :conditions => "feed_item_id = #{feed_item.id} and user_id = #{user.id}")
    assert_not_nil feed_item.taggings.find(:first, :conditions => "tag_id = #{tag.id} and user_id = #{user.id}")
    assert_not_nil user.taggings.find(:first, :conditions => "tag_id = #{tag.id} and feed_item_id = #{feed_item.id}")
  end
  
  it "tagging_strength_is_set" do
    user = Generate.user!
    feed_item = @feed_item
    tag = Tag(user, 'peerworks')
    tagging = Tagging.create(:user => user, :feed_item => feed_item, :tag => tag, :strength => 0)
    assert_valid tagging
    assert_equal 0, tagging.strength
  end
  
  it "strength_outside_0_to_1_is_invalid" do
    user = Generate.user!
    feed_item = @feed_item
    tag = Tag(user, 'peerworks')
    assert_valid Tagging.new(:user => user, :feed_item => feed_item, :tag => tag, :strength => 0.5)
    Tagging.new(:user => user, :feed_item => feed_item, :tag => tag, :strength => 1.1).should_not be_valid
    Tagging.new(:user => user, :feed_item => feed_item, :tag => tag, :strength => -0.1).should_not be_valid
    # boundaries
    Tagging.new(:user => user, :feed_item => feed_item, :tag => tag, :strength => 1).should be_valid
    Tagging.new(:user => user, :feed_item => feed_item, :tag => tag, :strength => 0).should be_valid
  end
  
  it "strength_must_be_a_number" do
    user = Generate.user!
    feed_item = @feed_item
    tag = Tag(user, 'peerworks')
    Tagging.new(:user => user, :feed_item => feed_item, :tag => tag, :strength => 'string').should_not be_valid
  end
  
  it "creating_duplicate_deletes_existing" do
    user = Generate.user!
    item = @feed_item
    tag = Tag(user, 'tag')
    first_tagging = user.taggings.create(:feed_item => item, :tag => tag)
    assert_valid first_tagging
    second_tagging = user.taggings.create(:feed_item => item, :tag => tag)
    assert_valid second_tagging
    assert_raise(ActiveRecord::RecordNotFound) { Tagging.find(first_tagging.id) }
  end
  
  it "users_is_allowed_manual_and_classifier_taggings_on_an_item" do
    user = Generate.user!
    item = @feed_item
    tag  = Tag(user, 'tag')
    
    assert_valid first = user.taggings.create(:feed_item => item, :tag => tag)
    assert_valid second = user.taggings.create(:feed_item => item, :tag => tag, :classifier_tagging => true)
    assert_nothing_raised(ActiveRecord::RecordNotFound) { Tagging.find(first.id) }
    assert_nothing_raised(ActiveRecord::RecordNotFound) { Tagging.find(second.id) }
    assert_equal(2, user.taggings.size)
  end
  
  it "cannot_create_taggings_without_user" do
    tag = 
    Tagging.new(:feed_item => @feed_item, :tag => Generate.tag!).should_not be_valid
  end
  
  it "cannot_create_taggings_without_feed_item" do
    user = Generate.user!
    Tagging.new(:user => user, :tag => Generate.tag!(:user => user)).should_not be_valid
  end
  
  it "cannot_create_taggings_without_tag" do
    Tagging.new(:feed_item => @feed_item, :user => Generate.user!).should_not be_valid
  end
  
  it "cannot_create_tagging_with_invalid_tag" do
    user = Generate.user!
    Tagging.new(:feed_item => @feed_item, :user => user, :tag => Generate.tag(:user => user, :name => "")).should_not be_valid
  end
  
  it "create_with_tag_user_feed_item_is_valid" do
    user = Generate.user!
    Tagging.new(:user => user, :feed_item => @feed_item, :tag => Generate.tag!(:user => user)).should be_valid
  end
  
  it "should prevent deletion of a feed item with a tagging" do
    user = Generate.user!
    tag = Generate.tag!(:user => user)
    feed_item = @feed_item
    tagging = Tagging.create!(:user => user, :feed_item => feed_item, :tag => tag)
    lambda { feed_item.destroy }.should raise_error(ActiveRecord::StatementInvalid)
  end

  it "deletion_copies_tagging_to_deleted_taggings_table" do
    user = Generate.user!
    tag = Generate.tag!(:user => user)
    feed_item = @feed_item
    tagging = Tagging.create(:user => user, :feed_item => feed_item, :tag => tag, :strength => 0.75)
    assert_not_nil tagging
    assert_not_nil Tagging.find(tagging.id)
    
    assert_difference("DeletedTagging.count") do
      tagging.destroy
    end
    
    assert_raise ActiveRecord::RecordNotFound do Tagging.find(tagging.id) end
    assert DeletedTagging.find(:first, :conditions => ['user_id = ? and feed_item_id = ? and tag_id = ? and strength = ?',
                                                        user, feed_item, tag, 0.75])
  end
  
  it "taggings_are_immutable" do
    user = Generate.user!
    tag = Generate.tag!(:user => user)
    item = @feed_item
    tagging = Tagging.create(:user => user, :feed_item => item, :tag => tag)
    assert_not_nil tagging
    assert_valid tagging
    assert !tagging.new_record?
    tagging.tag = Tag(user, 'failed')
    assert !tagging.save
    tagging = Tagging.find(tagging.id)
    assert_equal tag, tagging.tag
    assert_equal user, tagging.user
    assert_equal item, tagging.feed_item
  end
   
  it "classifier_tagging_defaults_to_false" do
    user = Generate.user!
    tag = Generate.tag!(:user => user)
    user.taggings.create(:feed_item => @feed_item, :tag => tag).should_not be_classifier_tagging
  end
end