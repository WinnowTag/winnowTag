# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
require File.dirname(__FILE__) + '/../spec_helper'

require 'tag'

shared_examples_for "FeedItem update attributes from atom" do
  it "should set the title" do
    @item.title.should == @atom.title
  end
  
  it "should set the updated date" do
    @item.updated.should == @atom.updated
  end
  
  it "should set the link to alternate" do
    @item.link.should == @atom.alternate.href
  end
  
  it "should set the collector link to self" do
    @item.collector_link.should == @atom.self.href
  end
  
  it "should set the author" do
    @item.author.should == @atom.authors.first.name
  end
  
  it "should set the content" do
    @item.content.content.should == @atom.content.to_s
  end
end

describe FeedItem do
  fixtures :users
  
  describe "sorting" do
    it "properly sorts the feed items by newest first" do
      user_1 = User.create! valid_user_attributes
        
      tag_1 = Tag.create! valid_tag_attributes(:user_id => user_1.id)
      tag_2 = Tag.create! valid_tag_attributes(:user_id => user_1.id)
      
      FeedItem.delete_all
      feed_item_1 = valid_feed_item!(:updated => Date.today)
      feed_item_2 = valid_feed_item!(:updated => Date.today - 1)
        
      FeedItem.find_with_filters(:user => user_1, :order => 'newest').should == [feed_item_1, feed_item_2]
    end
    
    it "properly sorts the feed items by oldest first" do
      user_1 = User.create! valid_user_attributes
        
      tag_1 = Tag.create! valid_tag_attributes(:user_id => user_1.id)
      tag_2 = Tag.create! valid_tag_attributes(:user_id => user_1.id)
      
      FeedItem.delete_all
      feed_item_1 = valid_feed_item!(:updated => Date.today)
      feed_item_2 = valid_feed_item!(:updated => Date.today - 1)
        
      FeedItem.find_with_filters(:user => user_1, :order => 'oldest').should == [feed_item_2, feed_item_1]
    end
    
    xit "properly sorts the feed items by tag strength first" do
      user_1 = User.create! valid_user_attributes
        
      tag_1 = Tag.create! valid_tag_attributes(:user_id => user_1.id)
      tag_2 = Tag.create! valid_tag_attributes(:user_id => user_1.id)
      tag_3 = Tag.create! valid_tag_attributes(:user_id => user_1.id)
      
      FeedItem.delete_all
      feed_item_1 = valid_feed_item!
      feed_item_2 = valid_feed_item!
      
      tagging_1 = Tagging.create! :user_id => user_1.id, :feed_item_id => feed_item_1.id, :tag_id => tag_1.id, :strength => 1
      tagging_2 = Tagging.create! :user_id => user_1.id, :feed_item_id => feed_item_2.id, :tag_id => tag_2.id, :strength => 1      
      tagging_3 = Tagging.create! :user_id => user_1.id, :feed_item_id => feed_item_2.id, :tag_id => tag_3.id, :strength => 1
      
      FeedItem.find_with_filters(:user => user_1, :order => 'oldest').should == [feed_item_2, feed_item_1]
    end
  end
  
  describe ".find_with_filters" do
    it "Properly filters feed items with included private tag and excluded public tag" do
      user_1 = User.create! valid_user_attributes
      user_2 = User.create! valid_user_attributes
        
      tag_1 = Tag.create! valid_tag_attributes(:user_id => user_1.id)
      tag_2 = Tag.create! valid_tag_attributes(:user_id => user_2.id, :public => true)
      tag_3 = Tag.create! valid_tag_attributes(:user_id => user_1.id)
    
      tag_subscription = TagSubscription.create! :tag_id => tag_1.id, :user_id => user_1.id
    
      feed_item_1 = valid_feed_item!
      feed_item_2 = valid_feed_item!
      feed_item_3 = valid_feed_item!
    
      tagging_1 = Tagging.create! :user_id => user_1.id, :feed_item_id => feed_item_1.id, :tag_id => tag_1.id
      tagging_2 = Tagging.create! :user_id => user_2.id, :feed_item_id => feed_item_2.id, :tag_id => tag_2.id
      tagging_3 = Tagging.create! :user_id => user_1.id, :feed_item_id => feed_item_3.id, :tag_id => tag_3.id
    
      user_1.tag_exclusions.create! :tag_id => tag_2.id
    
      FeedItem.find_with_filters(:user => user_1, :tag_ids => tag_1.id.to_s, :order => 'id').should == [feed_item_1]
    end

    it "Properly filters feed items with included private tag, excluded private tag, and excluded public tag" do
      user_1 = User.create! valid_user_attributes
      user_2 = User.create! valid_user_attributes
        
      tag_1 = Tag.create! valid_tag_attributes(:user_id => user_1.id)
      tag_2 = Tag.create! valid_tag_attributes(:user_id => user_2.id, :public => true)
      tag_3 = Tag.create! valid_tag_attributes(:user_id => user_1.id)
    
      tag_subscription = TagSubscription.create! :tag_id => tag_1.id, :user_id => user_1.id
    
      feed_item_1 = valid_feed_item!
      feed_item_2 = valid_feed_item!
      feed_item_3 = valid_feed_item!
      feed_item_4 = valid_feed_item!
    
      tagging_1 = Tagging.create! :user_id => user_1.id, :feed_item_id => feed_item_1.id, :tag_id => tag_1.id
      tagging_2 = Tagging.create! :user_id => user_2.id, :feed_item_id => feed_item_2.id, :tag_id => tag_2.id
      tagging_3 = Tagging.create! :user_id => user_1.id, :feed_item_id => feed_item_3.id, :tag_id => tag_3.id
      tagging_4 = Tagging.create! :user_id => user_1.id, :feed_item_id => feed_item_4.id, :tag_id => tag_1.id
      tagging_5 = Tagging.create! :user_id => user_2.id, :feed_item_id => feed_item_4.id, :tag_id => tag_2.id
    
      user_1.tag_exclusions.create! :tag_id => tag_2.id
      user_1.tag_exclusions.create! :tag_id => tag_3.id
    
      FeedItem.find_with_filters(:user => user_1, :tag_ids => tag_1.id.to_s, :order => 'id').should == [feed_item_1]
    end
  
    it "properly filters on globally excluded feeds" do
      user_1 = User.create! valid_user_attributes
    
      feed_1 = Feed.create! :via => "http://feedone.com"
    
      FeedItem.delete_all # :(
      feed_item_1 = valid_feed_item!(:feed_id => feed_1.id)
      feed_item_2 = valid_feed_item!(:feed_id => feed_1.id)
      feed_item_3 = valid_feed_item!(:feed_id => 2, :id => 3)
      feed_item_4 = valid_feed_item!(:feed_id => 3, :id => 4)
    
      user_1.excluded_feeds << feed_1
    
      FeedItem.find_with_filters(:user => user_1, :order => 'id').should == [feed_item_3, feed_item_4]
    end
    
    it "should work with a text filter" do
      user_1 = User.create! valid_user_attributes
      lambda { FeedItem.find_with_filters(:user => user_1, :text_filter => 'text')}.should_not raise_error
    end
    
    it "filters out read items" do
      user_1 = User.create! valid_user_attributes

      FeedItem.delete_all
      feed_item_1 = valid_feed_item!
      feed_item_2 = valid_feed_item!

      FeedItem.mark_read_for(user_1.id, feed_item_2.id)
      
      FeedItem.find_with_filters(:user => user_1, :read_items => false, :order => "id").should == [feed_item_1]
    end
    
    it "can include read items" do
      user_1 = User.create! valid_user_attributes

      FeedItem.delete_all
      feed_item_1 = valid_feed_item!(:id => 1)
      feed_item_2 = valid_feed_item!(:id => 2)

      FeedItem.mark_read_for(user_1.id, feed_item_2.id)
      
      FeedItem.find_with_filters(:user => user_1, :read_items => true, :order => "id").should == [feed_item_1, feed_item_2]
    end
  end  
  
  describe "update_from_atom" do
    before(:each) do
      @before_count = FeedItem.count
      @atom = Atom::Entry.new do |atom|
        atom.title = "Item Title"
        atom.updated = Time.now
        atom.id = "urn:peerworks.org:feed_item#1"
        atom.links << Atom::Link.new(:rel => 'self', :href => 'http://collector/1')
        atom.links << Atom::Link.new(:rel => 'alternate', :href => 'http://example.com')
        atom.authors << Atom::Person.new(:name => 'Author')
        atom.content = Atom::Content::Html.new('<p>content</p>')
      end
      
      @item = FeedItem.find(1)
      @item.update_from_atom(@atom)
    end
    
    it_should_behave_like "FeedItem update attributes from atom"
    
    it "should not create a new item" do
      FeedItem.count.should == @before_count
    end
    
    describe "with different id" do
      it "should not update the attributes" do
        lambda { FeedItem.find(2).update_from_atom(@atom) }.should raise_error(ArgumentError)
        FeedItem.find(2).title.should_not == @atom.title
      end
      
      it "should raise ArgumentError" do
        lambda { FeedItem.find(2).update_from_atom(@atom) }.should raise_error(ArgumentError)
      end
    end
  end
  
  describe "find_or_create_from_atom" do
    before(:each) do
      @before_count = FeedItem.count
      @atom = Atom::Entry.new do |atom|
        atom.title = "Item Title"
        atom.updated = Time.now
        atom.id = "urn:peerworks.org:feed_item#333"
        atom.links << Atom::Link.new(:rel => 'self', :href => 'http://collector/1')
        atom.links << Atom::Link.new(:rel => 'alternate', :href => 'http://example.com')
        atom.authors << Atom::Person.new(:name => 'Author')
        atom.content = Atom::Content::Html.new('<p>content</p>')
      end
    end
    
    describe "with a complete entry" do
      before(:each) do
        @item = FeedItem.find_or_create_from_atom(@atom)
      end
    
      it_should_behave_like "FeedItem update attributes from atom"
      
      it "should set the id" do
        @item.id.should == 333
      end
          
      it "should create a new feed item" do
        FeedItem.count.should == (@before_count + 1)
      end
    end
    
    describe "with a complete entry and an existing id" do
      before(:each) do
        @atom.id = "urn:peerworks.org:feed_item#1"
        @item = FeedItem.find_or_create_from_atom(@atom)        
      end
      
      it "should not be a new record" do
        @item.should_not be_new_record
      end
      
      it "should not create a new record" do
        FeedItem.count.should == @before_count
      end
      
      it_should_behave_like "FeedItem update attributes from atom"
    end
    
    describe "without an id" do
      before(:each) do
        @atom.id = nil
      end
      
      it "should reject the item" do
        lambda { FeedItem.find_or_create_from_atom(@atom) }.should raise_error(ActiveRecord::RecordNotSaved)
      end      
    end
    
    describe "with an invalid id" do
      before(:each) do
        @atom.id = "urn:peerworks.org:feed_item"
      end
      
      it "should reject the item" do
        lambda { FeedItem.find_or_create_from_atom(@atom) }.should raise_error(ActiveRecord::RecordNotSaved)
      end
    end
    
    describe "without a title" do
      before(:each) do
        @atom.title = nil
        @item = FeedItem.find_or_create_from_atom(@atom)
      end
      
      it "should set the title to 'Unknown Title'" do
        @item.title.should == 'Unknown Title'
      end
    end
    
    describe "without an author" do
      before(:each) do
        @atom.authors.clear
        @item = FeedItem.find_or_create_from_atom(@atom)
      end
      
      it "should set the author to nil" do
        @item.author.should be_nil
      end
    end    
    
    describe "without alternate link" do
      before(:each) do
        @atom.links.delete(@atom.alternate)
      end
      
      it "should reject the item" do
        lambda { FeedItem.find_or_create_from_atom(@atom) }.should raise_error(ActiveRecord::RecordInvalid)
      end
    end
    
    describe "without collector link" do
      before(:each) do
        @atom.links.delete(@atom.self)
        @item = FeedItem.find_or_create_from_atom(@atom)
      end
            
      it "should set the collector link to nil" do
        @item.collector_link.should be_nil
      end
    end
  end
  
  describe "to_atom" do
    fixtures :feed_item_contents
    before(:each) do
      @item = FeedItem.find(1)
      @atom = @item.to_atom(:base_uri => 'http://winnow.mindloom.org')
    end
    
    it "should include the title" do
      @atom.title.should == @item.title
    end
    
    it "should include the id" do
      @atom.id.should == "urn:peerworks.org:entry##{@item.id}"
    end
    
    it "should include the author" do
      @atom.authors.first.should_not be_nil
      @atom.authors.first.name.should == @item.author
    end
    
    it "should include the link" do
      @atom.alternate.href.should == @item.link
    end
    
    it "should include a link to the feed" do
      @atom.links.detect {|l| l.rel == 'http://peerworks.org/feed'}.should_not be_nil
      @atom.links.detect {|l| l.rel == 'http://peerworks.org/feed'}.href.should == "urn:peerworks.org:feed##{@item.feed_id}"
    end
    
    it "should include the content" do
      @atom.content.to_s.should == @item.content.content
    end
  end
  
  describe "to_atom with non-utf8" do
    before(:each) do
      @item = FeedItem.find(1)
      @item.content.content = "this is not utf-8 \227"
      @atom = @item.to_atom(:base_uri => 'http://winnow.mindloom.org')
    end
    
    it "should fix non-utf-8 content" do
      lambda { @atom.to_xml }.should_not raise_error
      @atom.to_xml.should match(/this is not utf-8/)
    end
  end
    
  describe '.archive' do
    before(:each) do
      @before_count = FeedItem.count
      ActiveRecord::Base.record_timestamps = false
    end
    
    after(:each) do
      ActiveRecord::Base.record_timestamps = true
    end
    
    it "should delete items older than the parameter" do
      item = valid_feed_item!(:updated => 10.days.ago.getutc)
      FeedItem.archive_items(9.days.ago)
      lambda { item.reload }.should raise_error(ActiveRecord::RecordNotFound)
      FeedItem.count.should == @before_count
    end
    
    it "should delete items older than 30 days by default" do
      older = valid_feed_item!(:updated => 31.days.ago.getutc, :content => FeedItemContent.new(:content => 'this is content'))
      newer = valid_feed_item!(:updated => 30.days.ago.getutc)
      FeedItem.archive_items
      lambda { older.reload }.should raise_error(ActiveRecord::RecordNotFound)
      lambda { newer.reload }.should_not raise_error(ActiveRecord::RecordNotFound)
      FeedItem.count.should == (@before_count + 1)
    end
    
    it "should exclude items with manual taggings" do
      item = valid_feed_item!(:updated => 31.days.ago.getutc)
      user = User.find(1)
      tag = Tag.create!(:user => user, :name => 'newtag')
      Tagging.create!(:tag => tag, :feed_item => item, :user => user)
      
      FeedItem.archive_items
      lambda { item.reload }.should_not raise_error(ActiveRecord::RecordNotFound)
      FeedItem.count.should == (@before_count + 1)
    end
    
    it "should delete items with only classifier taggings older than 30 days" do
      item = valid_feed_item!(:updated => 31.days.ago.getutc)
      user = User.find(1)
      tag = Tag.create!(:user => user, :name => 'newtag')
      tagging = user.taggings.create!(:tag => tag, :feed_item => item, :classifier_tagging => true, :created_on => 31.days.ago.getutc)
      
      FeedItem.archive_items
      lambda { item.reload }.should raise_error(ActiveRecord::RecordNotFound)
    end
    
    it "should delete old items with recent classifier tagging" do
      item = valid_feed_item!(:updated => 31.days.ago.getutc)
      user = User.find(1)
      tag = Tag.create!(:user => user, :name => 'newtag')
      tagging = user.taggings.create!(:tag => tag, :feed_item => item, :classifier_tagging => true)
      
      FeedItem.archive_items
      lambda { item.reload }.should raise_error(ActiveRecord::RecordNotFound)
    end
    
    it "should not delete old items with recent user tagging" do
      item = valid_feed_item!(:updated => 31.days.ago.getutc)
      user = User.find(1)
      tag = Tag.create!(:user => user, :name => 'newtag')
      tagging = user.taggings.create!(:tag => tag, :feed_item => item, :classifier_tagging => false)
      
      FeedItem.archive_items
      lambda { item.reload }.should_not raise_error(ActiveRecord::RecordNotFound)
    end
      
    it "should not delete items with a classifier and a manual tagging" do
      item = valid_feed_item!(:updated => 31.days.ago.getutc)
      user = User.find(1)
      tag = Tag.create!(:user => user, :name => 'newtag')
      user.taggings.create!(:tag => tag, :feed_item => item, :classifier_tagging => true, :created_on => 31.days.ago.getutc)
      user.taggings.create!(:tag => tag, :feed_item => item, :classifier_tagging => false, :created_on => 31.days.ago.getutc)

      FeedItem.archive_items
      lambda { item.reload }.should_not raise_error(ActiveRecord::RecordNotFound)
    end
  end
  
  describe "from test/unit" do
    fixtures :users    
  
    # Tests for the find_with_filters method
    it "find_with_show_untagged_returns_all_items" do
      feed_items = FeedItem.find_with_filters(:user => users(:quentin), :order => 'id')
      assert_equal FeedItem.find(1, 2, 3, 4), feed_items
    end
  
    it "find_with_negatives_includes_negativey_tagged_items" do
      user = users(:quentin)
      tag = Tag(user, 'tag')
      Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag)
      Tagging.create(:user => user, :feed_item => FeedItem.find(4), :tag => tag, :strength => 0)
    
      expected = FeedItem.find(2, 4)
      assert_equal(expected, FeedItem.find_with_filters(:user => user, :tag_ids => tag.id.to_s, :manual_taggings => true, :order => 'id'))
    end
  
    it "find_with_tag_filter_should_only_return_items_with_that_tag" do
      user = users(:quentin)
      tag = Tag(user, 'tag1')
      Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag)
    
      assert_equal [FeedItem.find(2)], FeedItem.find_with_filters(:user => user, :tag_ids => tag.id.to_s)
    end
  
    it "find_with_multiple_tag_filters_should_only_return_items_with_those_tags" do
      user = users(:quentin)
      tag = Tag(user, 'tag1')
      tag2 = Tag(user, 'tag2')
      Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag)
      Tagging.create(:user => user, :feed_item => FeedItem.find(3), :tag => tag2)
    
      expected = [FeedItem.find(2), FeedItem.find(3)]
      actual = FeedItem.find_with_filters(:user => users(:quentin), :tag_ids => "#{tag.id},#{tag2.id}", :order => 'id')
      assert_equal expected, actual
    end
  
    it "find_with_tag_filter_includes_negative_taggings" do
      user = users(:quentin)
      tag = Tag(user, 'tag1')
      Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag)
      Tagging.create(:user => user, :feed_item => FeedItem.find(3), :tag => tag, :strength => 0)

      assert_equal FeedItem.find(2, 3), FeedItem.find_with_filters(:user => user, :tag_ids => tag.id.to_s, :order => 'id')
    end  

    it "find_with_tag_filter_include_negative_taggings_with_positive_classifier_taggings" do
      user = users(:quentin)
      tag = Tag(user, 'tag1')
      Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag)
      Tagging.create(:user => user, :feed_item => FeedItem.find(3), :tag => tag, :classifier_tagging => true)
      Tagging.create(:user => user, :feed_item => FeedItem.find(3), :tag => tag, :strength => 0)

      assert_equal FeedItem.find(2, 3), FeedItem.find_with_filters(:user => user, :tag_ids => tag.id.to_s, :order => 'id')
    end
  
    it "find_with_tag_filter_should_ignore_other_users_tags" do
      user = users(:quentin)
      aaron = users(:aaron)
      tag = Tag(user, 'tag1')
      atag = Tag(aaron, 'tag1')
    
      Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag)
      Tagging.create(:user => users(:aaron), :feed_item => FeedItem.find(3), :tag => atag)

      assert_equal [FeedItem.find(2)], FeedItem.find_with_filters(:user => user, :tag_ids => tag.id.to_s)
    end
  
    it "find_with_tag_filter_should_include_classifier_tags" do
      user = users(:quentin)
      tag = Tag(user, 'tag1')
      Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag)
      Tagging.create(:user => user, :feed_item => FeedItem.find(3), :tag => tag, :classifier_tagging => true)

      assert_equal FeedItem.find(2, 3), FeedItem.find_with_filters(:user => user, :tag_ids => tag.id.to_s, :order => 'id')
    end
  
    it "find_with_excluded_tag_should_return_items_not_tagged_with_that_tag" do
      user = users(:quentin)
      tag1 = Tag(user, 'tag1')
      tag2 = Tag(user, 'tag2')
      Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag1)
      Tagging.create(:user => user, :feed_item => FeedItem.find(3), :tag => tag2)
  
      user.tag_exclusions.create! :tag_id => tag1.id
    
      assert_equal FeedItem.find(1, 3, 4), FeedItem.find_with_filters(:user => user, :order => 'id')
    end
  
    it "find_with_multiple_excluded_tags_should_return_items_not_tagged_with_those_tags" do
      user = users(:quentin)
      tag1 = Tag(user, 'tag1')
      tag2 = Tag(user, 'tag2')
      tag3 = Tag(user, 'tag3')
      Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag1)
      Tagging.create(:user => user, :feed_item => FeedItem.find(3), :tag => tag2)
      Tagging.create(:user => user, :feed_item => FeedItem.find(4), :tag => tag3)
  
      user.tag_exclusions.create! :tag_id => tag1.id
      user.tag_exclusions.create! :tag_id => tag2.id
    
      expected = FeedItem.find(1, 4)
      assert_equal expected, FeedItem.find_with_filters(:user => user, :order => 'id')
    end
  
    it "find_with_excluded_tag_should_return_items_not_tagged_with_that_tag" do
      user = users(:quentin)
      tag1 = Tag(user, 'tag1')
      tag2 = Tag(user, 'tag2')
      Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag1)
      Tagging.create(:user => user, :feed_item => FeedItem.find(3), :tag => tag2)
  
      user.tag_exclusions.create! :tag_id => tag1.id
    
      expected = FeedItem.find(1, 3, 4)
      assert_equal expected, FeedItem.find_with_filters(:user => user, :order => 'id')
    end
  
    it "find_with_included_and_excluded_tags_should_return_items_tagged_with_included_tag_and_not_the_excluded_tag" do
      user = users(:quentin)
      tag1 = Tag(user, 'tag1')
      tag2 = Tag(user, 'tag2')
      Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag1)
      Tagging.create(:user => user, :feed_item => FeedItem.find(3), :tag => tag1)
      Tagging.create(:user => user, :feed_item => FeedItem.find(3), :tag => tag2)
  
      user.tag_exclusions.create! :tag_id => tag2.id
    
      expected = [FeedItem.find(2)]
      assert_equal expected, FeedItem.find_with_filters(:user => user, :tag_ids => tag1.id.to_s, :order => 'id')
    end
  
    it "find_with_feed_filters_should_return_only_tagged_items_from_the_included_feed" do
      user = users(:quentin)
      tag1 = Tag(user, 'tag1')
    
      expected = FeedItem.find(1, 2, 3)
      actual = FeedItem.find_with_filters(:user => user, :feed_ids => "1", :order => 'id')
      assert_equal expected, actual
    end
  
    it "find_with_multiple_feed_filters_and_show_untagged_should_return_only_items_from_the_included_feeds" do
      feed_item5 = FeedItem.create!(:feed_id => 3, :link => "http://fifth")
    
      expected = FeedItem.find(1, 2, 3, 4)
      actual = FeedItem.find_with_filters(:user => users(:quentin), :feed_ids => "1,2", :order => 'id')
      assert_equal expected, actual
    end
      
    # it "find_with_feed_set_to_always_include_returns_all_tagged_items" do
    #   user = users(:quentin)
    #   tag1 = Tag(user, 'tag1')
    #   Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag1)
    #   
    #   view = users(:quentin).views.create!
    #   view.add_feed :always_include, 2
    # 
    #   expected = FeedItem.find(2, 4)
    #   actual = FeedItem.find_with_filters(:view => view, :order => 'id')
    #   assert_equal expected, actual
    # end
  
    # it "find_with_feed_set_to_always_include_and_show_untagged_items_returns_all_items" do
    #   user = users(:quentin)
    #   tag1 = Tag(user, 'tag1')
    #   Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag1)
    #   
    #   view = users(:quentin).views.create! :show_untagged => true
    #   view.add_feed :always_include, 2
    # 
    #   expected = FeedItem.find(1, 2, 3, 4)
    #   actual = FeedItem.find_with_filters(:view => view, :order => 'id')
    #   assert_equal expected, actual
    # end
  
    # it "find_with_feed_set_to_include_and_feed_set_to_always_include_and_show_untagged_returns_all_items_from_the_include_and_always_included_feed" do
    #   feed_item5 = FeedItem.create!(:feed_id => 3, :unique_id => "fifth", :link => "http://fifth")
    # 
    #   user = users(:quentin)
    #   tag1 = Tag(user, 'tag1')
    #   Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag1)
    # 
    #   view = users(:quentin).views.create! :show_untagged => true
    #   view.add_feed :include, 1
    #   view.add_feed :always_include, 2
    # 
    #   expected = FeedItem.find(1, 2, 3, 4)
    #   actual = FeedItem.find_with_filters(:view => view, :order => 'id')
    #   assert_equal expected, actual
    # end
  
    # it "find_with_feed_set_to_include_and_feed_set_to_always_include_and_show_untagged_returns_all_items_from_the_always_included_feed_and_tagged_items_from_the_included_feed" do
    #   feed_item5 = FeedItem.create!(:feed_id => 3, :unique_id => "fifth", :link => "http://fifth")
    # 
    #   user = users(:quentin)
    #   tag1 = Tag(user, 'tag1')
    #   Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag1)
    # 
    #   view = users(:quentin).views.create!
    #   view.add_feed :include, 1
    #   view.add_feed :always_include, 2
    # 
    #   expected = FeedItem.find(2, 4)
    #   actual = FeedItem.find_with_filters(:view => view, :order => 'id')
    #   assert_equal expected, actual
    # end
  
    # it "find_with_tag_filter_and_always_include_feed_filter_should_only_return_items_with_that_tag_or_in_that_feed" do
    #   user = users(:quentin)
    #   tag = Tag(user, 'tag1')
    #   Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag)
    #   
    #   view = user.views.create!
    #   view.add_tag :include, tag
    #   view.add_feed :always_include, 2
    #   
    #   assert_equal FeedItem.find(2, 4), FeedItem.find_with_filters(:view => view, :order => 'id')
    # end
  
    # it "find_with_tag_filter_and_multiple_always_include_feed_filter_should_only_return_items_with_that_tag_or_in_those_feeds" do
    #   user = users(:quentin)
    #   tag = Tag(user, 'tag1')
    #   Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag)
    #   
    #   view = user.views.create!
    #   view.add_tag :include, tag
    #   view.add_feed :always_include, 2
    #   view.add_feed :always_include, 1
    #   
    #   assert_equal FeedItem.find(1, 2, 3, 4), FeedItem.find_with_filters(:view => view, :order => 'id')
    # end
  
    it "find_with_tag_filter_and_feed_filter_should_only_return_items_with_that_tag_or_in_that_feed" do
      user = users(:quentin)
      tag = Tag(user, 'tag1')
      Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag)
      Tagging.create(:user => user, :feed_item => FeedItem.find(4), :tag => tag)
  
      assert_equal FeedItem.find(2, 4), FeedItem.find_with_filters(:user => user, :feed_ids => "2", :tag_ids => tag.id.to_s, :order => 'id')
    end
  
    it "options_for_filters_creates_text_filter" do
      assert_match(/MATCH/, FeedItem.send(:options_for_filters, :user => users(:quentin), :text_filter => "text")[:joins])
    end
    
    it "taggings_by_user_and_classifier_where_user_taggins_float_up" do
      user = users(:quentin)
      tag1 = Tag(user, 'tag1')
      tag2 = Tag(user, 'tag2')
      tag3 = Tag(user, 'tag3')
      fi = FeedItem.find(1)
    
      u_tagging1 = Tagging.create(:user => user, :feed_item => fi, :tag => tag1)
      c_tagging1 = Tagging.create(:user => user, :feed_item => fi, :tag => tag1, :classifier_tagging => true)
      c_tagging2 = Tagging.create(:user => user, :feed_item => fi, :tag => tag2, :classifier_tagging => true)
      u_tagging3 = Tagging.create(:user => user, :feed_item => fi, :tag => tag3)
    
      expected = [[tag1, [u_tagging1, c_tagging1]], [tag2, [c_tagging2]], [tag3, [u_tagging3]]]
      result = fi.taggings_by_user(user)
    
      assert_equal expected, result
    end
  
    it "find_by_user_with_caching" do
      user = users(:quentin)
      fi = FeedItem.find(1)
      tagging_1 = Tagging.create(:user => user, :feed_item => fi, :tag => Tag(user, 'tag1'))
      tagging_2 = Tagging.create(:user => user, :feed_item => fi, :tag => Tag(user, 'tag2'))
    
      fi.taggings.cached_taggings.merge!({user => [tagging_1, tagging_2]})
      assert_equal([tagging_1, tagging_2], fi.taggings.find_by_user(user))
    end
  
    it "find_by_user_with_caching_and_tag" do
      user = users(:quentin)
      fi = FeedItem.find(1)
      tagging_1 = Tagging.create(:user => user, :feed_item => fi, :tag => Tag(user, 'tag1'))
      tagging_2 = Tagging.create(:user => user, :feed_item => fi, :tag => Tag(user, 'tag2'))
    
      fi.taggings.cached_taggings.merge!({user => [tagging_1, tagging_2]})
      assert_equal([tagging_1], fi.taggings.find_by_user(user, Tag(user, 'tag1')))
    end
  
    it "find_by_user_with_caching_and_multiple_users" do
      user = users(:quentin)
      u2 = users(:aaron)
      fi = FeedItem.find(1)
      tagging_1 = Tagging.create(:user => user, :feed_item => fi, :tag => Tag(user, 'tag1'))
      tagging_2 = Tagging.create(:user => user, :feed_item => fi, :tag => Tag(user, 'tag2'))
      tagging_3 = Tagging.create(:user => u2, :feed_item => fi, :tag => Tag(u2, 'tag1'))
      tagging_4 = Tagging.create(:user => u2, :feed_item => fi, :tag => Tag(u2, 'tag2'))
    
      fi.taggings.cached_taggings.merge!(user => [tagging_1, tagging_2], u2 => [tagging_3, tagging_4])
      assert_equal([tagging_1, tagging_2], fi.taggings.find_by_user(user))
      assert_equal([tagging_3, tagging_4], fi.taggings.find_by_user(u2))
    end
  
    it "find_by_tagger_with_caching_and_missing_tagger" do
      user = users(:quentin)
      u2 = users(:aaron)
      fi = FeedItem.find(1)
      tagging_1 = Tagging.create(:user => user, :feed_item => fi, :tag => Tag(user, 'tag1'))
      tagging_2 = Tagging.create(:user => user, :feed_item => fi, :tag => Tag(user, 'tag2'))
      tagging_3 = Tagging.create(:user => u2, :feed_item => fi, :tag => Tag(u2, 'tag1'))
      tagging_4 = Tagging.create(:user => u2, :feed_item => fi, :tag => Tag(u2, 'tag2'))
    
      fi.taggings.cached_taggings.merge!({user => [tagging_1, tagging_2]})
      assert_equal([tagging_3, tagging_4], fi.taggings.find_by_user(u2))
    end

    it "find_with_non_existent_include_tag_filter_should_ignore_the_nonexistent_tag" do
      user = users(:quentin)
      tag = Tag(user, 'tag1')
      Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag)
    
      assert_equal [FeedItem.find(2)], FeedItem.find_with_filters(:user => user, :tag_ids => "#{tag.id},#{tag.id + 1}")
    end

    it "find_with_non_existent_tag_exclude_filter_should_ignore_the_nonexistent_tag" do
      user = users(:quentin)
      tag = Tag(user, 'tag1')
      Tagging.create(:user => user, :feed_item => FeedItem.find(2), :tag => tag)
    
      user.tag_exclusions.create! :tag_id => tag.id
      user.tag_exclusions.create! :tag_id => tag.id + 1
    
      assert_equal FeedItem.find(1,3,4), FeedItem.find_with_filters(:user => user, :order => 'id')
    end
  
    it "including_both_subscribed_and_private_tags_returns_feed_items_from_either_tag" do
      quentin = users(:quentin)
      aaron = users(:aaron)
    
      f1 = FeedItem.find(1)
      f2 = FeedItem.find(2)
    
      tag1 = Tag(quentin, 'tag1')
      tag2 = Tag(aaron, 'tag2')
      tag2.public = true
      tag2.save!
    
      tagging_1 = Tagging.create(:user => quentin, :feed_item => f1, :tag => tag1)
      tagging_2 = Tagging.create(:user => aaron, :feed_item => f2, :tag => tag2)
    
      TagSubscription.create! :tag => tag2, :user => quentin
    
      assert_equal [f1, f2], FeedItem.find_with_filters(:user => quentin, :tag_ids => "#{tag1.id},#{tag2.id}", :order => 'id')
    end

  end
end
