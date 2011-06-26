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
    tagging.should be_valid
    tagging.strength.should == 0
  end
  
  it "strength_outside_0_to_1_is_invalid" do
    user = Generate.user!
    feed_item = @feed_item
    tag = Tag(user, 'peerworks')
    Tagging.new(:user => user, :feed_item => feed_item, :tag => tag, :strength => 0.5).should be_valid
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
    first_tagging.should be_valid
    second_tagging = user.taggings.create(:feed_item => item, :tag => tag)
    second_tagging.should be_valid
    assert_raise(ActiveRecord::RecordNotFound) { Tagging.find(first_tagging.id) }
  end
  
  it "users_is_allowed_manual_and_classifier_taggings_on_an_item" do
    user = Generate.user!
    item = @feed_item
    tag  = Tag(user, 'tag')
    
    first = user.taggings.create(:feed_item => item, :tag => tag)
    first.should be_valid
    second = user.taggings.create(:feed_item => item, :tag => tag, :classifier_tagging => true)
    second.should be_valid
    assert_nothing_raised(ActiveRecord::RecordNotFound) { Tagging.find(first.id) }
    assert_nothing_raised(ActiveRecord::RecordNotFound) { Tagging.find(second.id) }
    user.should have(2).taggings
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
  
  it "cannot create a tagging with an invalid tag" do
    user = Generate.user!
    tag = Generate.tag(:user => user, :name => "")
    tagging = Tagging.new(:feed_item => @feed_item, :user => user, :tag => tag)
    tagging.should_not be_valid
    tagging.should have(1).error
    tagging.errors.on(:tag).should == "can't be blank"
  end
  
  it "create_with_tag_user_feed_item_is_valid" do
    user = Generate.user!
    Tagging.new(:user => user, :feed_item => @feed_item, :tag => Generate.tag!(:user => user)).should be_valid
  end

  it "should prevent deletion of a feed item with a manual tagging" do
    user = Generate.user!
    tag = Generate.tag!(:user => user)
    tagging = Tagging.create!(:user => user, :feed_item => @feed_item, :tag => tag, :classifier_tagging => false)
    @feed_item.destroy.should be_false
    lambda { FeedItem.find(@feed_item.id) }.should_not raise_error(ActiveRecord::RecordNotFound)
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
    tagging.should_not be_nil
    tagging.should be_valid
    tagging.should_not be_new_record
    tagging.tag = Tag(user, 'failed')
    tagging.save.should be_false
    tagging = Tagging.find(tagging.id)
    tagging.tag.should == tag
    tagging.user.should == user
    tagging.feed_item.should == item
  end
   
  it "classifier_tagging_defaults_to_false" do
    user = Generate.user!
    tag = Generate.tag!(:user => user)
    user.taggings.create(:feed_item => @feed_item, :tag => tag).should_not be_classifier_tagging
  end
end