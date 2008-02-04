# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../spec_helper'

shared_examples_for "Feed updates attributes from Atom::Entry" do
  it "should set the title" do
    @feed.title.should == @atom.title
  end

  it "should set the via link" do
    @feed.via.should == @atom.links.detect {|l| l.rel == 'via'}.href
  end

  it "should set the alternate link" do
    @feed.alternate.should == @atom.alternate.href
  end

  it "should set the updated date" do
    @feed.updated.should == @atom.updated
  end

  it "should set the published date" do
    @feed.published.should == @atom.published
  end

  it "should set collector link from self" do
    @feed.collector_link.should == @atom.self.href
  end

  it "should set the sort title" do
    @feed.sort_title.should == @atom.title.downcase
  end
end

describe Feed do
  fixtures :feed_items, :feeds, :feed_item_contents
  
  describe "find_or_create_from_atom_entry" do
    before(:each) do
      @feed_count = Feed.count
      @atom = Atom::Entry.new do |atom|
        atom.title = "Feed Title"
        atom.updated = Time.now
        atom.published = Time.now.yesterday
        atom.id = "urn:peerworks.org:feed#222"
        atom.links << Atom::Link.new(:rel => 'via', :href => 'http://example.com/feed')
        atom.links << Atom::Link.new(:rel => 'self', :href => 'http://collector/1')
        atom.links << Atom::Link.new(:rel => 'alternate', :href => 'http://example.com')
      end      
    end
    
    describe "with complete entry and existing feed id" do
      before(:each) do
        @atom.id = "urn:peerworks.org:feed#1"
        @feed = Feed.find_or_create_from_atom_entry(@atom)
      end
      
      it "should not create a new feed" do
        Feed.count.should == @feed_count
      end
      
      it "should return existing feed" do
        @feed.should_not be_new_record
        @feed.id.should == 1
      end
      
      it_should_behave_like "Feed updates attributes from Atom::Entry"
    end
    
    describe 'with complete entry and new record' do
      before(:each) do        
        @feed = Feed.find_or_create_from_atom_entry(@atom)
      end
    
      it_should_behave_like "Feed updates attributes from Atom::Entry"
        
      it "should set the id" do
        @feed.id.should == 222
      end
        
      it "should create a new feed" do
        Feed.count.should == (@feed_count + 1)
      end
    end
    
    describe 'with missing id' do
      before(:each) do
        @atom.id = nil
      end
      
      it "should reject the feed" do
        lambda { Feed.find_or_create_from_atom_entry(@atom) }.should raise_error(ActiveRecord::RecordNotSaved)
      end
    end
    
    describe "with invalid id" do
      before(:each) do
        @atom.id = "http://example.com"
      end
      
      it "should reject the feed" do
        lambda { Feed.find_or_create_from_atom_entry(@atom) }.should raise_error(ActiveRecord::RecordNotSaved)
      end
    end
    
    describe 'with missing title' do
      before(:each) do
        @atom.title = nil
        @feed = Feed.find_or_create_from_atom_entry(@atom)
      end
      
      it "should set the title to ''" do
        @feed.title.should == ''        
      end
      
      it "should set the sort title to ''" do
        @feed.sort_title.should == ''
      end
    end
    
    describe 'with missing via' do
      before(:each) do
        @atom.links.delete(@atom.links.via)
        @feed = Feed.find_or_create_from_atom_entry(@atom)
      end
      
      it "should set the via link to nil" do
        @feed.via.should be_nil
      end
    end
    
    describe 'with missing self' do
      before(:each) do
        @atom.links.delete(@atom.links.self)
        @feed = Feed.find_or_create_from_atom_entry(@atom)
      end
      
      it "should set the collector link to nil" do
        @feed.collector_link.should be_nil
      end
    end
    
    describe 'with missing alternate' do
      before(:each) do
        @atom.links.delete(@atom.links.alternate)
        @feed = Feed.find_or_create_from_atom_entry(@atom)
      end
      
      it "should set the alternate to nil" do
        @feed.alternate.should be_nil
      end
    end    
  end
  
  describe "find_or_create_from_atom" do
    describe "with single page feed" do      
      before(:each) do
        @before_feed_count = Feed.count
        @before_feed_items_count = FeedItem.count
        @before_feed_item_content_count = FeedItemContent.count
        
        @atom = Atom::Feed.new do |a|
          a.id = "urn:peerworks.org:feed#444"
          a.title = "Feed Title"
          a.updated = Time.now
          a.published = Time.now.yesterday
          a.links << Atom::Link.new(:rel => 'self', :href => 'http://collector.org/444')
          a.links << Atom::Link.new(:rel => 'via', :href => 'http://example.org/feed')
          a.links << Atom::Link.new(:rel => 'alternate', :href => 'http://example.org')
          a.entries << Atom::Entry.new do |e|
            e.title = "Item Title 1"
            e.updated = Time.now
            e.id = "urn:peerworks.org:feed_item#333"
            e.links << Atom::Link.new(:rel => 'self', :href => 'http://collector/333')
            e.links << Atom::Link.new(:rel => 'alternate', :href => 'http://example.com/333')
            e.authors << Atom::Person.new(:name => 'Author')
            e.content = Atom::Content::Html.new('<p>content 1</p>')
          end
          a.entries << Atom::Entry.new do |e|
            e.title = "Item Title 2"
            e.updated = Time.now
            e.id = "urn:peerworks.org:feed_item#334"
            e.links << Atom::Link.new(:rel => 'self', :href => 'http://collector/334')
            e.links << Atom::Link.new(:rel => 'alternate', :href => 'http://example.com/334')
            e.authors << Atom::Person.new(:name => 'Author')
            e.content = Atom::Content::Html.new('<p>content 2</p>')
          end
        end
        
        @feed = Feed.find_or_create_from_atom(@atom)
      end
      
      it_should_behave_like "Feed updates attributes from Atom::Entry"
      
      it "should set the id" do
        @feed.id.should == 444
      end
      
      it "should be saved in the database" do
        Feed.count.should == (@before_feed_count + 1)
      end
      
      it "should add the items to the feed" do
        @feed.should have(@atom.entries.size).feed_items
      end
      
      it "should save the items in the database" do
        FeedItem.count.should == (@before_feed_items_count + @atom.entries.size)
      end
      
      it "should save the item content in the database" do
        FeedItemContent.count.should == (@before_feed_item_content_count + @atom.entries.size)
      end
    end
    
    describe "with multi page feed" do
      
    end
  end
  
  describe "update_from_atom_entry" do
    before(:each) do
      @atom = Atom::Entry.new do |atom|
        atom.title = "Feed Title"
        atom.updated = Time.now
        atom.published = Time.now.yesterday
        atom.id = "urn:peerworks.org:feed#1"
        atom.links << Atom::Link.new(:rel => 'via', :href => 'http://example.com/feed')
        atom.links << Atom::Link.new(:rel => 'self', :href => 'http://collector/1')
        atom.links << Atom::Link.new(:rel => 'alternate', :href => 'http://example.com')
      end
      
      @feed = Feed.find(1)
      @feed.update_from_atom(@atom)
    end
    
    it_should_behave_like "Feed updates attributes from Atom::Entry"
    
    it "should not change the id" do
      @feed.id.should == 1
    end
    
    describe "with different ids" do
      before(:each) do
        @original_feed = Feed.find(2)
        @feed = Feed.find(2)
      end
      
      it "should raise an ArgumentError" do
        lambda { @feed.update_from_atom(@atom) }.should raise_error(ArgumentError)
      end
      
      it "should not change anything" do
        lambda { @feed.update_from_atom(@atom) }.should raise_error(ArgumentError)
        @original_feed.attributes.should == @feed.attributes
      end
    end
  end
  
  describe 'search' do
    it "should find items by search term" do
      Feed.search(:search_term => 'ruby').size.should == 2
    end
    
    it "should skip duplicates" do
      Feed.create! valid_feed_attributes(:title => 'Duplicate', :duplicate_id => 1)
      Feed.search(:search_term => 'Duplicate').should be_empty
    end
  end
end