# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
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
  describe "sorting" do
    it "properly sorts the feed items by newest first" do
      user = Generate.user!
      tag1 = Generate.tag!(:user => user)
      tag2 = Generate.tag!(:user => user)
      
      feed_item1 = Generate.feed_item!(:updated => Date.today)
      feed_item2 = Generate.feed_item!(:updated => Date.today - 1)
        
      FeedItem.find_with_filters(:user => user, :order => 'date', :direction => "desc").should == [feed_item1, feed_item2]
    end
    
    it "properly sorts the feed items by oldest first" do
      user = Generate.user!
      tag1 = Generate.tag!(:user => user)
      tag2 = Generate.tag!(:user => user)
      
      feed_item1 = Generate.feed_item!(:updated => Date.today)
      feed_item2 = Generate.feed_item!(:updated => Date.today - 1)
        
      FeedItem.find_with_filters(:user => user, :order => 'date').should == [feed_item2, feed_item1]
    end
    
    it "properly sorts the feed items by tag strength first" do
      user = Generate.user!
      tag1 = Generate.tag!(:user => user)
      tag2 = Generate.tag!(:user => user)
      tag3 = Generate.tag!(:user => user)
      
      feed_item1 = Generate.feed_item!
      feed_item2 = Generate.feed_item!
      
      user.taggings.create!(:feed_item => feed_item1, :tag => tag1, :strength => 1)
      user.taggings.create!(:feed_item => feed_item2, :tag => tag2, :strength => 0.5)
      user.taggings.create!(:feed_item => feed_item2, :tag => tag3, :strength => 0.7)
      
      FeedItem.find_with_filters(:user => user, :order => 'strength').should == [feed_item2, feed_item1]
    end
  end
  
  describe ".find_with_filters select" do
    it "can flag items as unread" do
      user = Generate.user!
        
      feed_item = Generate.feed_item!(:updated => Date.today)
      
      expected, actual = [feed_item], FeedItem.find_with_filters(:user => user, :order => 'date', :direction => "desc", :mode => "all")
      expected.should == actual
      
      actual.first.should_not be_read_by_current_user
    end
    
    it "can flag items as read" do
      user = Generate.user!
        
      feed_item = Generate.feed_item!(:updated => Date.today)

      feed_item.read_by!(user)
      
      expected, actual = [feed_item], FeedItem.find_with_filters(:user => user, :order => 'date', :direction => "desc", :mode => "all")
      expected.should == actual
      
      actual.first.should be_read_by_current_user
    end
  end
  
  describe ".find_with_filters" do    
    it "Properly filters feed items with included private tag and excluded public tag" do
      user1 = Generate.user!
      user2 = Generate.user!
      tag1 = Generate.tag!(:user => user1)
      tag2 = Generate.tag!(:user => user2, :public => true)
      tag3 = Generate.tag!(:user => user1)
      user1.tag_subscriptions.create!(:tag => tag1)

      feed_item1 = Generate.feed_item!
      feed_item2 = Generate.feed_item!
      feed_item3 = Generate.feed_item!
    
      user1.taggings.create!(:feed_item => feed_item1, :tag => tag1)
      user2.taggings.create!(:feed_item => feed_item2, :tag => tag2)
      user1.taggings.create!(:feed_item => feed_item3, :tag => tag3)
    
      user1.tag_exclusions.create!(:tag => tag2)
    
      FeedItem.find_with_filters(:user => user1, :tag_ids => tag1.id.to_s, :order => 'id').should == [feed_item1]
    end

    it "Properly filters feed items with included private tag, excluded private tag, and excluded public tag" do
      user1 = Generate.user!
      user2 = Generate.user!
      tag1 = Generate.tag!(:user => user1)
      tag2 = Generate.tag!(:user => user2, :public => true)
      tag3 = Generate.tag!(:user => user1)
      user1.tag_subscriptions.create!(:tag => tag1)
    
      feed_item1 = Generate.feed_item!
      feed_item2 = Generate.feed_item!
      feed_item3 = Generate.feed_item!
      feed_item4 = Generate.feed_item!
    
      user1.taggings.create!(:feed_item => feed_item1, :tag => tag1)
      user2.taggings.create!(:feed_item => feed_item2, :tag => tag2)
      user1.taggings.create!(:feed_item => feed_item3, :tag => tag3)
      user1.taggings.create!(:feed_item => feed_item4, :tag => tag1)
      user2.taggings.create!(:feed_item => feed_item4, :tag => tag2)

      user1.tag_exclusions.create!(:tag => tag2)
      user1.tag_exclusions.create!(:tag => tag3)
    
      FeedItem.find_with_filters(:user => user1, :tag_ids => tag1.id.to_s, :order => 'id').should == [feed_item1]
    end
  
    it "properly filters on globally excluded feeds" do
      user = Generate.user!
      feed1 = Generate.feed!
      feed2 = Generate.feed!
      feed3 = Generate.feed!
    
      feed_item1 = Generate.feed_item!(:feed => feed1)
      feed_item2 = Generate.feed_item!(:feed => feed1)
      feed_item3 = Generate.feed_item!(:feed => feed2)
      feed_item4 = Generate.feed_item!(:feed => feed3)

      user.excluded_feeds << feed1
    
      FeedItem.find_with_filters(:user => user, :order => 'id').should == [feed_item3, feed_item4]
    end
    
    it "should work with a text filter" do
      user = Generate.user!
      lambda { FeedItem.find_with_filters(:user => user, :text_filter => 'text')}.should_not raise_error
    end
    
    it "filters out read items" do
      user = Generate.user!
      feed_item1 = Generate.feed_item!
      feed_item2 = Generate.feed_item!
      feed_item2.read_by!(user)
      
      FeedItem.find_with_filters(:user => user, :mode => "unread", :order => "id").should == [feed_item1]
    end
    
    it "can include read items" do
      user = Generate.user!
      feed_item1 = Generate.feed_item!
      feed_item2 = Generate.feed_item!
      feed_item2.read_by!(user)
      
      FeedItem.find_with_filters(:user => user, :mode => "all", :order => "id").should == [feed_item1, feed_item2]
    end
    
    it "filters out read items when there are more then 1 tags included" do
      user = Generate.user!
      tag1 = Generate.tag!(:user => user)
      tag2 = Generate.tag!(:user => user)
      feed_item = Generate.feed_item!

      user.taggings.create!(:feed_item => feed_item, :tag => tag1)
      user.taggings.create!(:feed_item => feed_item, :tag => tag2)

      feed_item.read_by!(user)
      
      FeedItem.find_with_filters(:user => user, :mode => "unread", :tag_ids => [tag1.id, tag2.id].join(","), :order => "id").should == []
    end
    
  end  
  
  describe "update_from_atom" do
    before(:each) do
      @item = Generate.feed_item!
      @before_count = FeedItem.count
      @atom = Atom::Entry.new do |atom|
        atom.title = "Item Title"
        atom.updated = Time.now
        atom.id = @item.uri
        atom.links << Atom::Link.new(:rel => 'self', :href => 'http://collector/1')
        atom.links << Atom::Link.new(:rel => 'alternate', :href => 'http://example.com')
        atom.authors << Atom::Person.new(:name => 'Author')
        atom.content = Atom::Content::Html.new('<p>content</p>')
      end
      
      @item.update_from_atom(@atom)
    end
    
    it_should_behave_like "FeedItem update attributes from atom"
    
    it "should not create a new item" do
      FeedItem.count.should == @before_count
    end
    
    describe "with different id" do
      it "should not update the attributes" do
        item = Generate.feed_item!
        lambda { item.update_from_atom(@atom) }.should raise_error(ArgumentError)
        item.reload.title.should_not == @atom.title
      end
    end
  end
  
  describe "find_or_create_from_atom" do
    before(:each) do
      @item = Generate.feed_item!
      @before_count = FeedItem.count
      @atom = Atom::Entry.new do |atom|
        atom.title = "Item Title"
        atom.updated = Time.now
        atom.id = "urn:uuid:blahblah"
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
        @item.uri.should == @atom.id
      end
          
      it "should create a new feed item" do
        FeedItem.count.should == (@before_count + 1)
      end
    end
    
    describe "with a complete entry and an existing id" do
      before(:each) do
        @atom.id = @item.uri
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
    before(:each) do
      @user = Generate.user!
      @tag1 = Generate.tag!(:user => @user)
      @tag2 = Generate.tag!(:user => @user)
      @item = Generate.feed_item!
      @item.taggings.create!(:tag => @tag1, :user => @user, :classifier_tagging => 0, :strength => 1)
      @item.taggings.create!(:tag => @tag1, :user => @user, :classifier_tagging => 1, :strength => 0)
      @item.taggings.create!(:tag => @tag2, :user => @user, :classifier_tagging => 0, :strength => 1)
      @atom = @item.to_atom(:base_uri => 'http://winnow.mindloom.org', :include_tags => @tag1)
    end
    
    it "should include the title" do
      @atom.title.should == @item.title
    end
    
    it "should include the id" do
      @atom.id.should == @item.uri
    end
    
    it "should include the updated date" do
      @atom.updated.should == @item.updated
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
      @atom.links.detect {|l| l.rel == 'http://peerworks.org/feed'}.href.should == "urn:peerworks.org:feed##{@item.id}"
    end
    
    it "should include the content" do
      @atom.content.to_s.should == @item.content.content
    end
    
    it "should include the source with the title of the feed" do
      @atom.source.title.should == @item.feed.title
    end
    
    it "should include the source with the alternate link of the feed" do
      @atom.source.links.detect{|l| l.rel == 'alternate'}.href.should == @item.feed.alternate
    end
    
    it "should include the source with the feed link of the feed" do
      @atom.source.links.detect {|l| l.rel == 'self'}.href.should == @item.feed.via
    end
    
    it "should include positive tags for the specified tag" do
      @atom.categories.detect {|cat| cat.scheme == "http://winnow.mindloom.org/#{@user.login}/tags/" && cat.term == @tag1.name }.should_not be_nil
    end
    
    it "should include negative tags for the specified tag" do
      @atom.links.detect {|l| l.rel == 'http://peerworks.org/classifier/negative-example' && l.href == "http://winnow.mindloom.org/#{@user.login}/tags/#{@tag1.name}"}.should_not be_nil
    end
    
    it "should not include positive tags for non-specified tags" do
      @atom.categories.detect {|cat| cat.scheme == "http://winnow.mindloom.org/#{@user.login}/tags" && cat.term == @tag2.name }.should be_nil
    end
  end
  
  describe "to_atom without an author" do
    it "should not output an author" do
      item = Generate.feed_item!(:author => nil)
      item.to_atom.should have(0).authors
    end
  end
  
  describe "to_atom with non-utf8" do
    before(:each) do
      @item = FeedItem.new(:feed_id => 1, :updated => 2.days.ago, :created_on => 2.days.ago, 
                           :link => "http://example.com/rss", :title => "Example RSS Feed", 
                           :author => "Example Author", :uri => "urn:uuid:item30")
      @item.save!
      @content = FeedItemContent.new(:content => "this is not utf-8 \227")
      @content.feed_item_id = @item.id
      @content.save!
      @atom = @item.to_atom(:base_uri => 'http://winnow.mindloom.org')
    end
    
    it "should fix non-utf-8 content" do
      lambda { @atom.to_xml }.should_not raise_error
      @atom.to_xml.should match(/this is not utf-8/)
    end
  end

  describe "from test/unit" do
    before(:each) do
      @feed_item1 = Generate.feed_item!
      @feed_item2 = Generate.feed_item!
      @feed_item3 = Generate.feed_item!
      @feed_item4 = Generate.feed_item!
    end
    
    it "find_with_show_untagged_returns_all_items" do
      FeedItem.find_with_filters(:user => Generate.user!, :order => 'id').should == [@feed_item1, @feed_item2, @feed_item3, @feed_item4]
    end
  
    it "find_with_negatives_includes_negativey_tagged_items" do
      user = Generate.user!
      tag = Generate.tag!(:user => user)
      user.taggings.create!(:feed_item => @feed_item1, :tag => tag)
      user.taggings.create!(:feed_item => @feed_item2, :tag => tag, :strength => 0)
    
      FeedItem.find_with_filters(:user => user, :tag_ids => tag.id.to_s, :mode => "trained", :order => 'id').should == [@feed_item1, @feed_item2]
    end
  
    it "find_with_tag_filter_should_only_return_items_with_that_tag" do
      user = Generate.user!
      tag = Generate.tag!(:user => user)
      user.taggings.create!(:feed_item => @feed_item1, :tag => tag)
    
      FeedItem.find_with_filters(:user => user, :tag_ids => tag.id.to_s).should == [@feed_item1]
    end
  
    it "find_with_multiple_tag_filters_should_only_return_items_with_those_tags" do
      user = Generate.user!
      tag1 = Generate.tag!(:user => user)
      tag2 = Generate.tag!(:user => user)
      user.taggings.create!(:feed_item => @feed_item1, :tag => tag1)
      user.taggings.create!(:feed_item => @feed_item2, :tag => tag2)

      FeedItem.find_with_filters(:user => user, :tag_ids => [tag1.id, tag2.id].join(","), :order => 'id').should == [@feed_item1, @feed_item2]
    end
  
    it "find_with_tag_filter_includes_negative_taggings" do
      user = Generate.user!
      tag = Generate.tag!(:user => user)
      user.taggings.create!(:feed_item => @feed_item1, :tag => tag)
      user.taggings.create!(:feed_item => @feed_item2, :tag => tag, :strength => 0)

      FeedItem.find_with_filters(:user => user, :tag_ids => tag.id.to_s, :order => 'id').should == [@feed_item1, @feed_item2]
    end  

    it "find_with_tag_filter_include_negative_taggings_with_positive_classifier_taggings" do
      user = Generate.user!
      tag = Generate.tag!(:user => user)
      user.taggings.create!(:feed_item => @feed_item1, :tag => tag)
      user.taggings.create!(:feed_item => @feed_item2, :tag => tag, :classifier_tagging => true)
      user.taggings.create!(:feed_item => @feed_item2, :tag => tag, :strength => 0)

      FeedItem.find_with_filters(:user => user, :tag_ids => tag.id.to_s, :order => 'id').should == [@feed_item1, @feed_item2]
    end
  
    it "find_with_tag_filter_should_ignore_other_users_tags" do
      user1 = Generate.user!
      user2 = Generate.user!
      tag1 = Generate.tag!(:user => user1)
      tag2 = Generate.tag!(:user => user2)
      user1.taggings.create!(:feed_item => @feed_item1, :tag => tag1)
      user2.taggings.create!(:feed_item => @feed_item2, :tag => tag2)

      FeedItem.find_with_filters(:user => user1, :tag_ids => tag1.id.to_s).should == [@feed_item1]
    end
  
    it "find_with_tag_filter_should_include_classifier_tags" do
      user = Generate.user!
      tag = Generate.tag!(:user => user)
      user.taggings.create!(:feed_item => @feed_item1, :tag => tag)
      user.taggings.create!(:feed_item => @feed_item2, :tag => tag, :classifier_tagging => true)

      FeedItem.find_with_filters(:user => user, :tag_ids => tag.id.to_s, :order => 'id').should == [@feed_item1, @feed_item2]
    end
  
    it "find_with_excluded_tag_should_return_items_not_tagged_with_that_tag" do
      user = Generate.user!
      tag1 = Generate.tag!(:user => user)
      tag2 = Generate.tag!(:user => user)
      user.taggings.create!(:feed_item => @feed_item1, :tag => tag1)
      user.taggings.create!(:feed_item => @feed_item2, :tag => tag2)
      user.tag_exclusions.create!(:tag_id => tag1.id)
    
      FeedItem.find_with_filters(:user => user, :order => 'id').should == [@feed_item2, @feed_item3, @feed_item4]
    end
  
    it "find_with_multiple_excluded_tags_should_return_items_not_tagged_with_those_tags" do
      user = Generate.user!
      tag1 = Generate.tag!(:user => user)
      tag2 = Generate.tag!(:user => user)
      tag3 = Generate.tag!(:user => user)
      user.taggings.create!(:feed_item => @feed_item1, :tag => tag1)
      user.taggings.create!(:feed_item => @feed_item2, :tag => tag2)
      user.taggings.create!(:feed_item => @feed_item3, :tag => tag3)
      user.tag_exclusions.create!(:tag_id => tag1.id)
      user.tag_exclusions.create!(:tag_id => tag2.id)
    
      FeedItem.find_with_filters(:user => user, :order => 'id').should == [@feed_item3, @feed_item4]
    end
  
    it "find_with_included_and_excluded_tags_should_return_items_tagged_with_included_tag_and_not_the_excluded_tag" do
      user = Generate.user!
      tag1 = Generate.tag!(:user => user)
      tag2 = Generate.tag!(:user => user)
      user.taggings.create!(:feed_item => @feed_item1, :tag => tag1)
      user.taggings.create!(:feed_item => @feed_item2, :tag => tag1)
      user.taggings.create!(:feed_item => @feed_item2, :tag => tag2)
      user.tag_exclusions.create!(:tag_id => tag2.id)

      FeedItem.find_with_filters(:user => user, :tag_ids => tag1.id.to_s, :order => 'id').should == [@feed_item1]
    end
  
    it "find_with_feed_filters_should_return_only_items_from_the_included_feed" do
      user = Generate.user!
    
      FeedItem.find_with_filters(:user => user, :feed_ids => @feed_item1.feed_id.to_s, :order => 'id').should == [@feed_item1]
    end
  
    it "find_with_multiple_feed_filters_and_show_untagged_should_return_only_items_from_the_included_feeds" do
      user = Generate.user!
      Generate.feed_item!
    
      FeedItem.find_with_filters(:user => user, :feed_ids => [@feed_item1.feed_id, @feed_item2.feed_id].join(","), :order => 'id').should == [@feed_item1, @feed_item2]
    end
      
    it "find_with_tag_filter_and_feed_filter_should_only_return_items_with_that_tag_or_in_that_feed" do
      user = Generate.user!
      tag = Generate.tag!(:user => user)
      user.taggings.create!(:feed_item => @feed_item1, :tag => tag)
      user.taggings.create!(:feed_item => @feed_item2, :tag => tag)
  
      FeedItem.find_with_filters(:user => user, :feed_ids => [@feed_item1.feed_id, @feed_item2.feed_id].join(","), :tag_ids => tag.id.to_s, :order => 'id').should == [@feed_item1, @feed_item2]
    end
  
    it "options_for_filters_creates_text_filter" do
      FeedItem.send(:options_for_filters, :user => Generate.user!, :text_filter => "text")[:joins].should =~ /MATCH/
    end
    
    it "find_with_non_existent_include_tag_filter_should_ignore_the_nonexistent_tag" do
      user = Generate.user!
      tag = Generate.tag!(:user => user)
      user.taggings.create!(:feed_item => @feed_item1, :tag => tag)
    
      FeedItem.find_with_filters(:user => user, :tag_ids => [tag.id, tag.id + 1].join(",")).should == [@feed_item1]
    end

    it "find_with_non_existent_tag_exclude_filter_should_ignore_the_nonexistent_tag" do
      user = Generate.user!
      tag = Generate.tag!(:user => user)
      user.taggings.create!(:feed_item => @feed_item1, :tag => tag)
      user.tag_exclusions.create!(:tag_id => tag.id)
      user.tag_exclusions.create!(:tag_id => tag.id + 1)
    
      FeedItem.find_with_filters(:user => user, :order => 'id').should == [@feed_item2, @feed_item3, @feed_item4]
    end
  
    it "including_both_subscribed_and_private_tags_returns_feed_items_from_either_tag" do
      user1 = Generate.user!
      user2 = Generate.user!
      tag1 = Generate.tag!(:user => user1)
      tag2 = Generate.tag!(:user => user2, :public => true)
      user1.taggings.create!(:feed_item => @feed_item1, :tag => tag1)
      user2.taggings.create!(:feed_item => @feed_item2, :tag => tag2)
      TagSubscription.create!(:tag => tag2, :user => user1)

      FeedItem.find_with_filters(:user => user1, :tag_ids => [tag1.id, tag2.id].join(","), :order => 'id').should == [@feed_item1, @feed_item2]
    end
  end
end
