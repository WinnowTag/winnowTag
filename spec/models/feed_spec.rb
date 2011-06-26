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

  it "should set collector link from self" do
    @feed.collector_link.should == @atom.self.href
  end
end

describe Feed do
  describe "title" do
    it "sets the feed's title to be a the alternate link's host if no title was set" do
      Generate.feed!(:title => nil, :alternate => "http://google.com/feed.atom").sort_title.should == "googlecom"
    end
    
    it "sets the feed's title to be a the via link's host if no title or alternate link was set" do
      Generate.feed!(:title => nil, :alternate => nil, :via => "http://google.com/feed.atom").sort_title.should == "googlecom"
    end
  end

  describe "sort_title" do
    it "sets the feed's sort_title to be a downcased version of the title with leading articles and non-word characters removed" do
      Generate.feed!(:title => "Some-Fe*ed").sort_title.should == "somefeed"
      Generate.feed!(:title => "A So'me #Feed").sort_title.should == "somefeed"
      Generate.feed!(:title => "An $Some :Feed").sort_title.should == "somefeed"
      Generate.feed!(:title => "The So.me Fe_ed").sort_title.should == "somefeed"
    end
  end
  
  describe "find_or_create_from_atom_entry" do
    before(:each) do
      @original_feed = Generate.feed!
      @feed_count = Feed.count
      @atom = Atom::Entry.new do |atom|
        atom.title = "Feed Title"
        atom.updated = Time.now
        atom.id = "urn:uuid:blah-blah"
        atom.links << Atom::Link.new(:rel => 'via', :href => 'http://example.com/feed')
        atom.links << Atom::Link.new(:rel => 'self', :href => 'http://collector/1')
        atom.links << Atom::Link.new(:rel => 'alternate', :href => 'http://example.com')
      end      
    end
    
    describe "with complete entry and existing feed id" do
      before(:each) do
        @atom.id = @original_feed.uri
        @feed = Feed.find_or_create_from_atom_entry(@atom)
      end
      
      it "should not create a new feed" do
        Feed.count.should == @feed_count
      end
      
      it "should return existing feed" do
        @feed.should_not be_new_record
        @feed.id.should == @original_feed.id
      end
      
      it_should_behave_like "Feed updates attributes from Atom::Entry"
    end
    
    describe 'with complete entry and new record' do
      before(:each) do        
        @feed = Feed.find_or_create_from_atom_entry(@atom)
      end
    
      it_should_behave_like "Feed updates attributes from Atom::Entry"
        
      it "should set the id" do
        @feed.uri.should == @atom.id
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
    
    describe 'with duplicate link' do
      before(:each) do
        @user = Generate.user!
        @original_feed = Generate.feed!
        @duplicate_feed = Generate.feed!
        @atom.id = @duplicate_feed.uri
        @atom.links << Atom::Link.new(:rel => "http://peerworks.org/duplicateOf", :href => @original_feed.uri)
        @feed = Feed.find_or_create_from_atom_entry(@atom)
      end
      
      it "should set the duplicate_id" do
        @feed.duplicate_id.should == @original_feed.id
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
          a.id = "urn:uuid:feed444"
          a.title = "Feed Title"
          a.updated = Time.now
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
        @feed.uri.should == "urn:uuid:feed444"
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
      it "needs examples"
    end
  end
  
  describe "update_from_atom_entry" do
    before(:each) do
      @feed = Generate.feed!

      @atom = Atom::Entry.new do |atom|
        atom.title = "Feed Title"
        atom.updated = Time.now
        atom.published = Time.now.yesterday
        atom.id = @feed.uri
        atom.links << Atom::Link.new(:rel => 'via', :href => 'http://example.com/feed')
        atom.links << Atom::Link.new(:rel => 'self', :href => 'http://collector/1')
        atom.links << Atom::Link.new(:rel => 'alternate', :href => 'http://example.com')
      end
      @feed.update_from_atom(@atom)
    end
    
    it_should_behave_like "Feed updates attributes from Atom::Entry"
    
    it "should not change the id" do
      @feed.uri.should == @atom.id
    end
    
    describe "with different ids" do
      before(:each) do
        @feed = Generate.feed!
        @original_attributes = @feed.attributes.freeze
      end
      
      it "should raise an ArgumentError" do
        lambda { @feed.update_from_atom(@atom) }.should raise_error(ArgumentError)
      end
      
      it "should not change anything" do
        lambda { @feed.update_from_atom(@atom) }.should raise_error(ArgumentError)
        @feed.attributes.should == @original_attributes
      end
    end
  end

  describe 'search' do
    it "should find items by search term" do
      Generate.feed!(:title => "Ruby Lang")
      Generate.feed!(:title => "Ruby on Rails")
      Generate.feed!(:title => "Python")
      
      Feed.search(:text_filter => 'ruby').size.should == 2
    end
    
    it "should skip duplicates" do
      feed = Generate.feed!(:title => "Ruby Lang")
      duplicate = Generate.feed!(:title => "Duplicate", :duplicate => feed)
      Feed.search(:text_filter => 'Duplicate').should be_empty
    end
  end
  
  describe 'destroy' do 
    before(:each) do
      @user = Generate.user!
      @tag = Generate.tag!(:user => @user)      
      @feed = Generate.feed!
    end
    
    it "should destroy a feed with no items" do
      @feed.destroy
      lambda { Feed.find(@feed.id) }.should raise_error(ActiveRecord::RecordNotFound)
    end
    
    describe 'feed with items' do
      before(:each) do 
        Generate.feed_item!(:feed => @feed)
        Generate.feed_item!(:feed => @feed)
      end
      
      it "should destroy a feed with items with no taggings" do
        @feed.destroy
        lambda { Feed.find(@feed.id) }.should raise_error(ActiveRecord::RecordNotFound)
      end
      
      it "should destroy all items in the feed with no taggings" do 
        item_ids = @feed.feed_item_ids
        @feed.destroy
        item_ids.each do |item_id|
          lambda { FeedItem.find(item_id) }.should raise_error(ActiveRecord::RecordNotFound)
        end  
      end
    end
    
    describe 'feed with items with classifier taggings' do
      before(:each) do
        @item_with_only_classifier_taggings = Generate.feed_item!(:feed => @feed)
        Tagging.create(:user => @user, :tag => @tag, :feed_item => @item_with_only_classifier_taggings, :classifier_tagging => true)
      end
      
      it "should destroy a feed with items with only classifier taggings" do
        @feed.destroy
        lambda { Feed.find(@feed.id) }.should raise_error(ActiveRecord::RecordNotFound)
      end
    
      it "should destroy all items with only classifier taggings" do
        @feed.destroy
        lambda { FeedItem.find(@item_with_only_classifier_taggings.id) }.should raise_error(ActiveRecord::RecordNotFound)
      end
      
      
      describe 'and manual taggings' do
        before(:each) do
          @item_with_manual_taggings = Generate.feed_item!(:feed => @feed) 
          @mt = Tagging.create(:user => @user, :tag => @tag, :feed_item => @item_with_manual_taggings, :classifier_tagging => false)
          @ct = Tagging.create(:user => @user, :tag => @tag, :feed_item => @item_with_manual_taggings, :classifier_tagging => true)
        end

        it "should not destroy a feed with items with manual taggings" do
          @feed.destroy
          lambda { Feed.find(@feed.id) }.should_not raise_error(ActiveRecord::RecordNotFound)
        end
        
        it "should delete all items without manual taggings" do
          @feed.destroy
          lambda { FeedItem.find(@item_with_only_classifier_taggings.id) }.should raise_error(ActiveRecord::RecordNotFound)
        end
        
        it "should not delete any items with manual taggings" do
          @feed.destroy
          lambda { FeedItem.find(@item_with_manual_taggings.id) }.should_not raise_error(ActiveRecord::RecordNotFound)
        end
        
        it "should delete classifier taggings from items with manual taggings" do
          @feed.destroy
          lambda { Tagging.find(@ct.id) }.should raise_error(ActiveRecord::RecordNotFound)
        end
        
        it "should not delete manual taggings from items with manual taggings" do
          @feed.destroy
          lambda { Tagging.find(@mt.id) }.should_not raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end
end
