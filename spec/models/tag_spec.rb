# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe Tag do
  CLASSIFIER_NS = 'http://peerworks.org/classifier'

  describe "associations" do
    before(:each) do
      @tag = Tag.new
    end

    it "has many tag subscriptions" do
      @tag.should have_many(:tag_subscriptions)
    end

    it "belongs to user" do
      @tag.should belong_to(:user)
    end

    it "has many comments" do
      @tag.should have_many(:comments)
    end
  end

  describe "sort_name" do
    it "sets the tag's sort_name to be a downcased version of the name with leading articles and non-word characters removed" do
      Generate.tag!(:name => "Some-Fe*ed").sort_name.should == "somefeed"
      Generate.tag!(:name => "A So'me #Feed").sort_name.should == "somefeed"
      Generate.tag!(:name => "An $Some :Feed").sort_name.should == "somefeed"
      Generate.tag!(:name => "The So?me Fe_ed").sort_name.should == "somefeed"
    end
  end

  describe "tagging counts" do
    it "is properly calculated for private tags" do
      u = Generate.user!
      fi1 = Generate.feed_item!
      fi2 = Generate.feed_item!
      classifier = Tag(u, 'classifier')
      classifier_diff = Tag(u, 'classifier_diff')
      classifier_neg = Tag(u, 'classifier_neg')
      classifier_pos = Tag(u, 'classifier_pos')
      empty = Tag(u, 'empty')
      peerworks = Tag(u, 'peerworks')
      test = Tag(u, 'test')
      Tagging.create(:user => u, :feed_item => fi2, :tag => classifier, :classifier_tagging => true)
      Tagging.create(:user => u, :feed_item => fi1, :tag => classifier_diff)
      Tagging.create(:user => u, :feed_item => fi2, :tag => classifier_diff, :classifier_tagging => true)
      Tagging.create(:user => u, :feed_item => fi1, :tag => classifier_neg, :strength => 0)
      Tagging.create(:user => u, :feed_item => fi1, :tag => classifier_neg, :classifier_tagging => true)
      Tagging.create(:user => u, :feed_item => fi1, :tag => classifier_pos)
      Tagging.create(:user => u, :feed_item => fi1, :tag => classifier_pos, :classifier_tagging => true)
      Tagging.create(:user => u, :feed_item => fi1, :tag => peerworks)
      Tagging.create(:user => u, :feed_item => fi2, :tag => peerworks)
      Tagging.create(:user => u, :feed_item => fi1, :tag => test)
      Tagging.create(:user => u, :feed_item => fi2, :tag => test, :strength => 0)

      tags = u.tags.search(:user => u, :order => "name")
      assert_equal 7, tags.size

      assert_equal classifier, tag = tags.shift
      assert_equal 0, tag.positive_count.to_i
      assert_equal 0, tag.negative_count.to_i
      assert_equal 1, tag.classifier_count.to_i

      assert_equal classifier_diff, tag = tags.shift
      assert_equal 1, tag.positive_count.to_i
      assert_equal 0, tag.negative_count.to_i
      assert_equal 1, tag.classifier_count.to_i

      assert_equal classifier_neg, tag = tags.shift
      assert_equal 0, tag.positive_count.to_i
      assert_equal 1, tag.negative_count.to_i
      assert_equal 0, tag.classifier_count.to_i

      assert_equal classifier_pos, tag = tags.shift
      assert_equal 1, tag.positive_count.to_i
      assert_equal 0, tag.negative_count.to_i
      assert_equal 0, tag.classifier_count.to_i

      assert_equal empty, tag = tags.shift
      assert_equal 0, tag.positive_count.to_i
      assert_equal 0, tag.negative_count.to_i
      assert_equal 0, tag.classifier_count.to_i

      assert_equal peerworks, tag = tags.shift
      assert_equal 2, tag.positive_count.to_i
      assert_equal 0, tag.negative_count.to_i
      assert_equal 0, tag.classifier_count.to_i

      assert_equal test, tag = tags.shift
      assert_equal 1, tag.positive_count.to_i
      assert_equal 1, tag.negative_count.to_i
      assert_equal 0, tag.classifier_count.to_i
    end
  
    it "is properly calculated for subscribed tags" do
      u = Generate.user!
      u2 = Generate.user!
      fi1 = Generate.feed_item!
      fi2 = Generate.feed_item!
      peerworks = Tag(u, 'peerworks')
      test = Tag(u, 'test')
      tag = Tag(u, 'tag')
      Tagging.create(:user => u, :feed_item => fi1, :tag => peerworks)
      Tagging.create(:user => u, :feed_item => fi2, :tag => peerworks)
      Tagging.create(:user => u, :feed_item => fi1, :tag => test)
      TagSubscription.create(:tag_id => tag.id, :user => u2)

      tags = Tag.search(:user => u2, :own => true, :order => "name")
      assert_equal 1, tags.size
      assert_equal 'tag', tags[0].name
      assert_equal 0, tags[0].positive_count.to_i
    end
  end
  
  describe "specs" do
    it "filters items by search term" do
      user_1 = Generate.user!
      user_2 = Generate.user!(:login => "everman")
    
      tag_1 = Generate.tag!(:user => user_1, :name => "The best tag ever in the world", :description => "")
      tag_2 = Generate.tag!(:user => user_1, :name => "Another Tag", :description => "The second best tag ever")
      tag_3 = Generate.tag!(:user => user_2, :name => "My cool tag", :description => "")
    
      tags = Tag.search(:user => user_1, :text_filter => "ever", :order => "id")
      tags.should == [tag_1, tag_2, tag_3]
    
      tags = Tag.search(:user => user_1, :text_filter => "world")
      tags.should == [tag_1]
    
      tags = Tag.search(:user => user_1, :text_filter => "second")
      tags.should == [tag_2]
    
      tags = Tag.search(:user => user_1, :text_filter => "man")
      tags.should == [tag_3]
    end
  
    it "should update it's timestamp when a new tag is created" do
      user = Generate.user!
      feed_item = Generate.feed_item!
  
      tag = Generate.tag!(:user => user, :name => "No this tag is the best tag in the world")
      updated_on = tag.updated_on = Time.now.yesterday

      Tagging.create! :tag => tag, :user => user, :feed_item => feed_item, :strength => 1    
      tag.updated_on.should > updated_on
    end
  
    it "should update it's timestamp when a tag is deleted" do
      user = Generate.user!
      feed_item = Generate.feed_item!
  
      tag = Generate.tag!(:user => user, :name => "No this tag is the best tag in the world")
      tagging = Tagging.create! :tag => tag, :user => user, :feed_item => feed_item, :strength => 1    
      updated_on = tag.updated_on = Time.now.yesterday
      tagging.destroy
      tag.updated_on.should > updated_on      
    end
    
    it "should delete classifier taggings" do
      user = Generate.user!
      feed_item_1 = Generate.feed_item!
      feed_item_2 = Generate.feed_item!
      tag = Generate.tag!(:user => user, :name => "mytag")
    
      t1 = Tagging.create! :user => user, :feed_item => feed_item_1, :tag => tag
      t2 = Tagging.create! :user => user, :feed_item => feed_item_2, :tag => tag, :classifier_tagging => true
    
      tag.taggings.should == [t1, t2]    
      tag.reload
      tag.delete_classifier_taggings!
      tag.taggings.should == [t1]
    end
  end

  describe "#potentially_undertrained?" do
    before(:each) do
      @user = Generate.user!
      @tag = Generate.tag!(:user => @user, :name => 'mytag')

      6.times { Generate.feed_item! }
    end
    
    it "should return true if positive taggings less than 6" do
      FeedItem.all(:limit => 5).each do |i|
        @tag.taggings.create!(:feed_item => i, :user => @user, :classifier_tagging => false, :strength => 1)
      end
      
      @tag.should have(5).positive_taggings
      @tag.should be_potentially_undertrained
    end
    
    it "should return false if positive taggings 6" do
      FeedItem.find(:all).each do |i|
        @tag.taggings.create!(:feed_item => i, :user => @user, :classifier_tagging => false, :strength => 1)
      end
      
      @tag.should have_at_least(5).positive_taggings
      @tag.should_not be_potentially_undertrained
    end
  end

  describe '.to_atom' do
    before(:each) do
      @atom = Tag.to_atom(:base_uri => 'http://winnow.mindloom.org')
    end
    
    it "should have feed.updated as the maximum last created time" do
      @atom.updated.should == Tag.maximum(:created_on)
    end
    
    it "should have an entry for every tag" do
      @atom.should have(Tag.count).entries
    end
    
    it "should have a title for every tag" do
      @atom.entries.each do |e|
        e.title.should_not be_nil
      end
    end
    
    it "should have an id for every tag" do
      @atom.entries.each do |e|
        e.id.should_not be_nil
      end
    end
    
    it "should have a updated for every tag" do
      @atom.entries.each do |e|
        e.updated.should_not be_nil
      end
    end
    
    it "should have a link to training for every tag" do
      @atom.entries.each do |e|
        e.links.detect {|l| l.rel = "#{CLASSIFIER_NS}/training" && l.href =~ %r{http://winnow.mindloom.org/\w+/tags/\w+/training.atom} }.should_not be_nil
      end
    end
  end
end

describe 'to_atom', :shared => true do
  it "should set atom:title to the :user::tag name" do
    @atom.title.should == "#{@user.login}:#{@tag.name}"
  end

  it "should set atom:updated to the last trained date" do
    @atom.updated.should == @tag.updated_on
  end

  it "should set classifier:classified to the last classified date" do
    @atom[CLASSIFIER_NS, 'classified'].first.should == @tag.last_classified_at.xmlschema
  end

  it "should set classifier:bias the bias" do
    @atom[CLASSIFIER_NS, 'bias'].first.should == @tag.bias.to_s
  end

  it "should set the atom:id to :base_uri/tags/:id" do
    @atom.id.should == "http://winnow.mindloom.org/#{@user.login}/tags/#{@tag.name}"
  end
  
  it "should have a category on the feed" do
    @atom.should have(1).categories
  end

  it "should have the right term on the category" do
    @atom.categories.first.term.should == @tag.name
  end

  it "should have the right scheme on the category" do
    @atom.categories.first.scheme.should == "http://winnow.mindloom.org/#{@user.login}/tags/"
  end

  it "should have an http://peerworks.org/classifier/edit link that refers to the classifier tagging resource" do
    @atom.links.detect {|l| l.rel == "#{CLASSIFIER_NS}/edit" }.should_not be_nil
    @atom.links.detect {|l| l.rel == "#{CLASSIFIER_NS}/edit" }.href.should == "http://winnow.mindloom.org/#{@user.login}/tags/#{@tag.name}/classifier_taggings.atom"
  end
  
  # TODO: This needs to be fixed and re-enabled
  xit "should be parseable by ratom" do
    lambda { Atom::Feed.load_feed(@atom.to_xml) }.should_not raise_error
  end
  
  xit "should contain the full content for each item" do
    @atom.entries.each do |e|
      e.content.to_s.size.should > 0
    end
  end
end

describe Tag do
  describe "#to_atom" do
    before(:each) do
      @user = Generate.user!
      @tag = Generate.tag! :user => @user, :name => 'mytag', :last_classified_at => Time.now
      @user.taggings.create!(:feed_item => @feed_item1 = Generate.feed_item!, :tag => @tag, :strength => 1)
      @user.taggings.create!(:feed_item => @feed_item2 = Generate.feed_item!, :tag => @tag, :strength => 1)
      @user.taggings.create!(:feed_item => @feed_item3 = Generate.feed_item!, :tag => @tag, :strength => 0)
      @user.taggings.create!(:feed_item => @feed_item4 = Generate.feed_item!, :tag => @tag, :strength => 0.95, :classifier_tagging => true)
      @atom = @tag.to_atom(:base_uri => 'http://winnow.mindloom.org')
    end     
    
    it_should_behave_like 'to_atom'
    
    it "should have a self link" do
      @atom.links.detect {|l| l.rel == "self" }.should_not be_nil
      @atom.links.detect {|l| l.rel == "self" }.href.should == "http://winnow.mindloom.org/#{@user.login}/tags/#{@tag.name}.atom"
    end
    
    it "should have a training link" do
      @atom.links.detect {|l| l.rel == "#{CLASSIFIER_NS}/training" }.should_not be_nil
      @atom.links.detect {|l| l.rel == "#{CLASSIFIER_NS}/training" }.href.should == "http://winnow.mindloom.org/#{@user.login}/tags/#{@tag.name}/training.atom"
    end      
    
    it "should contain all the tagged items" do
      @atom.should have(3).entries
      @atom.entries.detect {|e| e.id == @feed_item1.uri}.should_not be_nil
      @atom.entries.detect {|e| e.id == @feed_item2.uri}.should_not be_nil
      @atom.entries.detect {|e| e.id == @feed_item4.uri}.should_not be_nil
    end
    
    it "should not contain any negatively tagged items" do
      @atom.entries.detect {|e| e.id == @feed_item3.uri}.should be_nil
    end
    
    it "should have atom:category for the classifier example" do
      entry = @atom.entries.detect {|e| e.id == @feed_item4.uri}
      entry.categories.first.should_not be_nil
    end
    
    it "should have the terms for the classifier example" do
      @atom.entries.detect {|e| e.id == @feed_item4.uri}.categories.first.term.should == @tag.name
    end
    
    it "should have the scheme for the classifier example" do
      @atom.entries.detect {|e| e.id == @feed_item4.uri}.categories.first.scheme.should == "http://winnow.mindloom.org/#{@user.login}/tags/"
    end
    
    it "should have the strength for the classifier example" do
      @atom.entries.detect {|e| e.id == @feed_item4.uri}.categories.first[CLASSIFIER_NS, 'strength'].first.should == "0.95"
    end
    
    describe "with since" do
      it "should only return items with updated date after :since" do
        @atom = @tag.to_atom(:base_uri => 'http://winnow.mindloom.org', :since => Time.now)
        @atom.entries.detect {|e| e.id == @feed_item1.uri}.should be_nil
      end
    end
    
    describe "with space in the name" do
      before(:each) do
        @tag.name = "my tag"
        @atom = @tag.to_atom(:base_uri => 'http://winnow.mindloom.org')
      end
      
      it "should escape the training URL" do
        @atom.links.detect {|l| l.rel == "#{CLASSIFIER_NS}/training" }.href.should == "http://winnow.mindloom.org/#{@user.login}/tags/my%20tag/training.atom"
      end
      
      it "should escape the edit URL" do        
        @atom.links.detect {|l| l.rel == "#{CLASSIFIER_NS}/edit" }.href.should == "http://winnow.mindloom.org/#{@user.login}/tags/my%20tag/classifier_taggings.atom"
      end
    end
    
    describe "with training only" do   
      before(:each) do
        @atom = @tag.to_atom(:training_only => true, :base_uri => 'http://winnow.mindloom.org')
      end
    
      it_should_behave_like 'to_atom'
      
      it "should have a self link" do
        @atom.links.detect {|l| l.rel == "self" }.should_not be_nil
        @atom.links.detect {|l| l.rel == "self" }.href.should == "http://winnow.mindloom.org/#{@user.login}/tags/#{@tag.name}/training.atom"
      end
    
      it "should have an alternate link that points to the base" do
        @atom.links.detect {|l| l.rel == "alternate" }.should_not be_nil
        @atom.links.detect {|l| l.rel == "alternate" }.href.should == "http://winnow.mindloom.org/#{@user.login}/tags/#{@tag.name}.atom"
      end
    
      it "should contain all the manually tagged items" do
        @atom.should have(3).entries
        @atom.entries.detect {|e| e.id == @feed_item1.uri}.should_not be_nil
        @atom.entries.detect {|e| e.id == @feed_item2.uri}.should_not be_nil
        @atom.entries.detect {|e| e.id == @feed_item3.uri}.should_not be_nil
      end
    
      it "should not contain any classifier only tagged items" do
        @atom.entries.detect {|e| e.id == @feed_item4.uri}.should be_nil
      end
            
      it "should have a classifier:negative-example for all negative examples" do
        @atom.entries.detect {|e| e.id == @feed_item3.uri}.links.detect do |l| 
          l.rel == "http://peerworks.org/classifier/negative-example" && l.href == "http://winnow.mindloom.org/#{@user.login}/tags/#{@tag.name}"
        end.should_not be_nil
      end
        
      it "should have a atom:category for all positive examples" do
        @atom.entries.detect {|e| e.id == @feed_item1.uri}.should have(1).categories
        @atom.entries.detect {|e| e.id == @feed_item2.uri}.should have(1).categories
      end
      
      it "should have the tag name as the term for atom:categories" do
        @atom.entries.detect {|e| e.id == @feed_item1.uri}.categories.first.term.should == @tag.name
        @atom.entries.detect {|e| e.id == @feed_item2.uri}.categories.first.term.should == @tag.name
      end
    
      it "should have the users tag index as the scheme for the atom:categories" do
        @atom.entries.detect {|e| e.id == @feed_item1.uri}.categories.first.scheme.should == "http://winnow.mindloom.org/#{@user.login}/tags/"
        @atom.entries.detect {|e| e.id == @feed_item2.uri}.categories.first.scheme.should == "http://winnow.mindloom.org/#{@user.login}/tags/"
      end
    end
  end
end

describe 'create_taggings_from_atom', :shared => true do
  it "should create new classifier taggings for each entry in the atom" do
    @tag.create_taggings_from_atom(@atom)
    @tag.classifier_taggings.size.should == (@before_classifier_taggings_size + @number_of_new_taggings)
  end
  
  it "should leave the original user tagging intact" do
    @tag.create_taggings_from_atom(@atom)
    lambda { @ut.reload }.should_not raise_error(ActiveRecord::RecordNotFound)
  end
  
  it "should leave the original classifier tagging intact" do
    @tag.create_taggings_from_atom(@atom)
    lambda { @ct.reload }.should_not raise_error(ActiveRecord::RecordNotFound)
  end
  
  it "should update the original classifier tagging's strength" do
    @tag.create_taggings_from_atom(@atom)
    @ct.reload
    @ct.strength.should == @updated_strength
  end
  
  it "should have the new classifier tagging" do
    @tag.create_taggings_from_atom(@atom)
    @tag.classifier_taggings.find(:first, :conditions => ['feed_item_id = ? and classifier_tagging = 1', @feed_item3]).strength.should == 0.99
  end
  
  it "should not change the updated timestamp" do
    orig = @tag.updated_on
    @tag.create_taggings_from_atom(@atom)
    @tag.updated_on.should === orig
  end
  
  it "should update the classified_at timestamp" do
    @tag.create_taggings_from_atom(@atom)
    @tag.reload
    @tag.last_classified_at.should_not be_nil
  end
end

describe Tag do
  describe "#create_taggings_from_atom" do      
    before(:each) do
      @user = Generate.user!
      @tag = Generate.tag!(:user => @user)
      @feed_item1 = Generate.feed_item!
      @feed_item2 = Generate.feed_item!
      @feed_item3 = Generate.feed_item!
      @feed_item4 = Generate.feed_item!
      @ut = @tag.taggings.create!(:user => @user, :feed_item => @feed_item1, :classifier_tagging => false)
      @ct = @tag.taggings.create!(:user => @user, :feed_item => @feed_item2, :classifier_tagging => true, :strength => 0.95)
      @updated_strength = 0.97
      @before_classifier_taggings_size = @tag.classifier_taggings.size
      @number_of_new_taggings = 1
      
      @atom = Atom::Feed.new do |f|
        f.entries << Atom::Entry.new do |e|
          e.id = @feed_item3.uri
          e.categories << Atom::Category.new do |c|
            c.scheme = "http://winnow.mindloom.org/#{@user.login}/tags/"
            c.term = @tag.name
            c[CLASSIFIER_NS, 'strength'].as_attribute = true
            c[CLASSIFIER_NS, 'strength'] << ".99"
          end
        end
        f.entries << Atom::Entry.new do |e|
          e.id = @feed_item2.uri
          e.categories << Atom::Category.new do |c|
            c.scheme = "http://winnow.mindloom.org/#{@user.login}/tags/"
            c.term = @tag.name
            c[CLASSIFIER_NS, 'strength'].as_attribute = true
            c[CLASSIFIER_NS, 'strength'] << @updated_strength.to_s
          end
        end
      end
    end

    it_should_behave_like 'create_taggings_from_atom'

    describe 'with missing items in the document' do
      before(:each) do 
        @atom.entries << Atom::Entry.new do |e|
          e.id = "urn:uuid:FeedItemUnknown"
          e.categories << Atom::Category.new do |c|
            c.scheme = "http://winnow.mindloom.org/#{@user.login}/tags/"
            c.term = @tag.name
            c[CLASSIFIER_NS, 'strength'].as_attribute = true
            c[CLASSIFIER_NS, 'strength'] << "0.99"
          end
        end
      end
      it_should_behave_like 'create_taggings_from_atom'
    end

    describe 'with strength-less item in the document' do
      before(:each) do 
        @atom.entries << Atom::Entry.new do |e|
          e.id = @feed_item4.uri
        end
      end
      it_should_behave_like 'create_taggings_from_atom'
    end

    describe 'with bad id item in the document' do
      before(:each) do 
        @atom.entries << Atom::Entry.new do |e|
          e.id = " ks "          
          e.categories << Atom::Category.new do |c|
            c.scheme = "http://winnow.mindloom.org/#{@user.login}/tags/"
            c.term = @tag.name
            c[CLASSIFIER_NS, 'strength'].as_attribute = true
            c[CLASSIFIER_NS, 'strength'] << ".99"
          end
        end
      end
      it_should_behave_like 'create_taggings_from_atom'
    end

    describe 'with strength less than 0.9 item in the document' do
      before(:each) do 
        @atom.entries << Atom::Entry.new do |e|
          e.id = @feed_item4.uri
          e.categories << Atom::Category.new do |c|
            c.scheme = "http://winnow.mindloom.org/#{@user.login}/tags/"
            c.term = @tag.name
            c[CLASSIFIER_NS, 'strength'].as_attribute = true
            c[CLASSIFIER_NS, 'strength'] << ".8"
          end
        end
      end
      it_should_behave_like 'create_taggings_from_atom'
    end
  end

  describe "#replace_taggings_from_atom" do
    before(:each) do
      @user = Generate.user!
      @tag = Generate.tag!(:user => @user)
      @tag2 = Generate.tag!(:user => @user)
      feed_item1 = Generate.feed_item!
      feed_item2 = Generate.feed_item!
      feed_item3 = Generate.feed_item!
      @ut = @tag.taggings.create!(:user => @user, :feed_item => feed_item1, :classifier_tagging => false)
      @ct = @tag.taggings.create!(:user => @user, :feed_item => feed_item2, :classifier_tagging => true, :strength => 0.95)
      @ct2 = @tag2.taggings.create!(:user => @user, :feed_item => feed_item2, :classifier_tagging => true, :strength => 0.95)
            
      @atom = Atom::Feed.new do |f|
        f.entries << Atom::Entry.new do |e|
          e.id = feed_item3.uri
          e.categories << Atom::Category.new do |c|
            c.scheme = "http://winnow.mindloom.org/#{@user.login}/tags/"
            c.term = @tag.name
            c[CLASSIFIER_NS, 'strength'].as_attribute = true
            c[CLASSIFIER_NS, 'strength'] << "0.99"
          end
        end
        f.entries << Atom::Entry.new do |e|
          e.id = feed_item2.uri
          e.categories << Atom::Category.new do |c|
            c.scheme = "http://winnow.mindloom.org/#{@user.login}/tags/"
            c.term = @tag.name
            c[CLASSIFIER_NS, 'strength'].as_attribute = true
            c[CLASSIFIER_NS, 'strength'] << "0.95"
          end
        end
      end
    end
    
    it "should leave the user tagging intact" do
      @tag.replace_taggings_from_atom(@atom)
      lambda { @ut.reload }.should_not raise_error
    end
    
    it "should destroy the old classifier tagging" do
      @tag.replace_taggings_from_atom(@atom)
      lambda { @ct.reload }.should raise_error
    end
    
    it "should create new taggings" do
      @tag.replace_taggings_from_atom(@atom)
      @tag.reload
      @tag.classifier_taggings.size.should == @atom.entries.size
    end
    
    it "should not affect other tags" do
      @tag.replace_taggings_from_atom(@atom)
      lambda { @ct2.reload }.should_not raise_error
    end
  end
end

describe Tag do
  describe "validations" do
    it "requires a user to have unique tag names" do
      user = Generate.user!
      tag = Generate.tag!(:user => user, :name => "tag")
      tag2 = Generate.tag(:user => user, :name => "tag")

      tag2.should_not be_valid
      tag2.should have(1).error
      tag2.errors.on(:name).should == "has already been taken"
    end

    it "requries a user to have unique tag names even when the case is different" do
      user = Generate.user!
      tag = Generate.tag!(:user => user, :name => "TAG")
      tag2 = Generate.tag(:user => user, :name => "tag")

      tag2.should_not be_valid
      tag2.should have(1).error
      tag2.errors.on(:name).should == "has already been taken"
    end

    it "does not require different users to have unique tag names" do
      user = Generate.user!
      tag = Generate.tag!(:user => user, :name => "tag")
      user2 = Generate.user!
      tag2 = Generate.tag(:user => user2, :name => "tag")

      tag2.should be_valid
    end
  
    it "does not allow tags with no name" do
      user = Generate.user!
      tag = Generate.tag(:user => user, :name => "")
      tag.should_not be_valid
      tag.should have(1).error
      tag.errors.on(:name).should == "can't be blank"
    end

    it "does not allow tags with names longer than 255 characters" do
      user = Generate.user!
      tag = Generate.tag(:user => user, :name => "n" * 256)
      tag.should_not be_valid
      tag.should have(1).error
      tag.errors.on(:name).should == "is too long (maximum is 255 characters)"
    end
  
    it "does not allow tags with periods in the name" do
      user = Generate.user!
      tag = Generate.tag(:user => user, :name => "tag.name")
      tag.should_not be_valid
      tag.should have(1).error
      tag.errors.on(:name).should == I18n.t("winnow.errors.tag.invalid_format")
    end

    it "does not allow tags with non-ascii characters" do
      user = Generate.user!
      tag = Generate.tag(:user => user, :name => "50¢")
      tag.should_not be_valid
      tag.should have(1).error
      tag.errors.on(:name).should == I18n.t("winnow.errors.tag.invalid_format")
    end

    it "allows all ascii characters" do
      user = Generate.user!
      tag = Generate.tag(:user => user, :name => '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ ~!@#$%^&*()_+`-={}|[]\:";\'<>?,/')
      tag.should be_valid
    end
  end
  
  describe "from test/unit" do
    it "tag_function" do
      user = Generate.user!
      tag = Tag(user, 'tag1')
      assert tag.is_a?(Tag)
      assert_equal 'tag1', tag.name
      assert !tag.new_record?    
      tag2 = Tag(user, tag)
      assert_equal tag, tag2
    end
  
    it "sorting" do
      user = Generate.user!
      tag1 = Generate.tag!(:user => user, :name => "aaa")
      tag2 = Generate.tag!(:user => user, :name => "bbb")
      assert_equal([tag1, tag2], [tag1, tag2].sort)
      assert_equal([tag1, tag2], [tag2, tag1].sort)
    end
  
    it "sorting_is_case_insensitive" do
      user = Generate.user!
      tag1 = Generate.tag!(:user => user, :name => "aaa")
      tag2 = Generate.tag!(:user => user, :name => "Abb")
      assert_equal([tag1, tag2], [tag1, tag2].sort)
      assert_equal([tag1, tag2], [tag2, tag1].sort)
    end
  
    it "sorting_with_non_tag_raises_exception" do
      user = Generate.user!
      tag = Generate.tag!(:user => user)
      assert_raise(ArgumentError) { tag <=> 42 }
    end
  
    it "two_tags_belonging_to_different_users_are_different" do
      user1 = Generate.user!
      user2 = Generate.user!
      tag1 = Generate.tag!(:user => user1)
      tag2 = Generate.tag!(:user => user2)

      tag1.should_not == tag2
    end
  
    it "copy tag to another tag for the same user" do
      user = Generate.user!
      tag = Generate.tag!(:user => user)
      copy = Generate.tag!(:user => user)
      user.taggings.create!(:feed_item => Generate.feed_item!, :tag => tag)
      user.taggings.create!(:feed_item => Generate.feed_item!, :tag => tag)
      user.taggings.create!(:feed_item => Generate.feed_item!, :tag => tag)
      user.taggings.create!(:feed_item => Generate.feed_item!, :tag => tag, :classifier_tagging => true)
    
      tag.copy(copy)
      assert_equal(4, user.taggings.find_by_tag(copy).size)
      assert_equal(4, user.taggings.find_by_tag(tag).size)
    end
  
    it "copy tag to a tag for a different user" do
      user1 = Generate.user!
      user2 = Generate.user!
      tag1 = Generate.tag!(:user => user1)
      tag2 = Generate.tag!(:user => user2)

      user1.taggings.create!(:feed_item => Generate.feed_item!, :tag => tag1)
      user1.taggings.create!(:feed_item => Generate.feed_item!, :tag => tag1)
      user1.taggings.create!(:feed_item => Generate.feed_item!, :tag => tag1)
      user1.taggings.create!(:feed_item => Generate.feed_item!, :tag => tag1, :classifier_tagging => true)

      tag1.copy(tag2)
      assert_equal(4, user1.taggings.find_by_tag(tag1).size)
      assert_equal(4, user2.taggings.find_by_tag(tag2).size)
    end
  
    it "copy_with_the_same_name_raises_error" do
      user = Generate.user!
      tag = Generate.tag!(:user => user)
      user.taggings.create!(:feed_item => Generate.feed_item!, :tag => tag)
      user.taggings.create!(:feed_item => Generate.feed_item!, :tag => tag)
      user.taggings.create!(:feed_item => Generate.feed_item!, :tag => tag)
    
      assert_raise(ArgumentError) { tag.copy(tag) }
    end
  
    it "copy_to_other_user_when_tag_already_exists_raises_error" do
      user1 = Generate.user!
      user2 = Generate.user!
      tag = Generate.tag!(:user => user1)
      user1.taggings.create!(:feed_item => Generate.feed_item!, :tag => tag)
      user2.taggings.create!(:feed_item => Generate.feed_item!, :tag => tag)
    
      assert_raise(ArgumentError) { tag.copy(tag) }
    end
  
    it "copying_copies_the_tag_description_and_bias" do
      user = Generate.user!
      old_tag = Generate.tag!(:user => user, :description => "old tag description", :bias => 0.9)
      new_tag = Generate.tag!(:user => user, :description => "new tag description")
        
      old_tag.copy(new_tag)
    
      new_tag.reload
    
      assert_equal 0.9, new_tag.bias
      assert_equal "old tag description", new_tag.description
    end
  
    it "merge_into_another_tag" do
      user = Generate.user!
      old_tag = Generate.tag!(:user => user)
      new_tag = Generate.tag!(:user => user)
      feed_item1 = Generate.feed_item!
      feed_item2 = Generate.feed_item! 
      user.taggings.create!(:feed_item => feed_item1, :tag => old_tag)
      user.taggings.create!(:feed_item => feed_item2, :tag => new_tag)
    
      old_tag.merge(new_tag)
    
      assert_equal([], old_tag.taggings)
      assert_equal([feed_item1.id, feed_item2.id], new_tag.taggings.map(&:feed_item_id).sort)
    end
  
    it "merge_when_tag_exists_on_item" do
      user = Generate.user!
      old_tag = Generate.tag!(:user => user)
      new_tag = Generate.tag!(:user => user)
      feed_item = Generate.feed_item!
      user.taggings.create!(:feed_item => feed_item, :tag => old_tag)
      user.taggings.create!(:feed_item => feed_item, :tag => new_tag)
    
      old_tag.merge(new_tag)
    
      assert_equal([], old_tag.taggings.map(&:feed_item))
      assert_equal([feed_item], new_tag.taggings.map(&:feed_item))    
    end
  
    it "overwriting_a_tag" do
      user = Generate.user!
      old_tag = Generate.tag!(:user => user, :description => "old tag description", :bias => 0.9)
      new_tag = Generate.tag!(:user => user, :description => "new tag description")
      feed_item1 = Generate.feed_item!
      feed_item2 = Generate.feed_item!
      user.taggings.create!(:feed_item => feed_item1, :tag => old_tag)
      user.taggings.create!(:feed_item => feed_item2, :tag => new_tag)
    
      old_tag.overwrite(new_tag)
    
      new_tag.reload
    
      assert_equal [feed_item1], new_tag.taggings(:reload).map(&:feed_item)
      assert_equal 0.9, new_tag.bias
      assert_equal "old tag description", new_tag.description
    end
  end
  
  describe ".create_from_atom" do 
    before(:each) do
      @user = Generate.user!
      @orig_tag = Generate.tag!(:user => @user, :bias => 1.1)
      @fi1 = Generate.feed_item!
      @fi2 = Generate.feed_item!
      @fi3 = Generate.feed_item!
      
      @user.taggings.create!(:feed_item => @fi1, :tag => @orig_tag)
      @user.taggings.create!(:feed_item => @fi2, :tag => @orig_tag)
      @user.taggings.create!(:feed_item => @fi3, :tag => @orig_tag, :strength => 0)
      
      @atom = @orig_tag.to_atom(:training_only => true)
      
      @tag = @user.tags.create_from_atom(@atom)
    end
    
    it "should not have any errors" do
      @tag.errors.should be_empty
    end
    
    it "should create a tag with the same name" do
      @tag.name.should == @atom.title
    end
    
    it "should set the description of the tag to 'Imported on ...'" do
      @tag.description.should match(/^Imported on/)
    end
    
    it "should set the bias of the tag" do
      @tag.bias.should == 1.1
    end
    
    it "should set show_in_sidebar to true" do
      @tag.show_in_sidebar.should be_true
    end
    
    it "should create three taggings" do
      @tag.should have(3).taggings
    end
    
    it "should set the strength of the taggings" do
      @tag.taggings.find_by_feed_item_id(@fi1.id).strength.should == 1
      @tag.taggings.find_by_feed_item_id(@fi2.id).strength.should == 1
      @tag.taggings.find_by_feed_item_id(@fi3.id).strength.should == 0
    end
  end
end
