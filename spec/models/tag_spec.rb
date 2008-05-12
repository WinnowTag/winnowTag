require File.dirname(__FILE__) + '/../spec_helper'

describe Tag do
  fixtures :users, :feed_items, :feed_item_contents
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
  
  describe "tagging counts" do
    it "is properly calculated for private tags" do
      Tag.delete_all
      
      u = users(:quentin)
      fi1 = feed_items(:first)
      fi2 = feed_items(:forth)
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
      assert_equal 0, tag.training_count.to_i
      assert_equal 1, tag.classifier_count.to_i

      assert_equal classifier_diff, tag = tags.shift
      assert_equal 1, tag.positive_count.to_i
      assert_equal 0, tag.negative_count.to_i
      assert_equal 1, tag.training_count.to_i
      assert_equal 1, tag.classifier_count.to_i

      assert_equal classifier_neg, tag = tags.shift
      assert_equal 0, tag.positive_count.to_i
      assert_equal 1, tag.negative_count.to_i
      assert_equal 1, tag.training_count.to_i
      assert_equal 0, tag.classifier_count.to_i

      assert_equal classifier_pos, tag = tags.shift
      assert_equal 1, tag.positive_count.to_i
      assert_equal 0, tag.negative_count.to_i
      assert_equal 1, tag.training_count.to_i
      assert_equal 0, tag.classifier_count.to_i

      assert_equal empty, tag = tags.shift
      assert_equal 0, tag.positive_count.to_i
      assert_equal 0, tag.negative_count.to_i
      assert_equal 0, tag.training_count.to_i
      assert_equal 0, tag.classifier_count.to_i

      assert_equal peerworks, tag = tags.shift
      assert_equal 2, tag.positive_count.to_i
      assert_equal 0, tag.negative_count.to_i
      assert_equal 2, tag.training_count.to_i
      assert_equal 0, tag.classifier_count.to_i

      assert_equal test, tag = tags.shift
      assert_equal 1, tag.positive_count.to_i
      assert_equal 1, tag.negative_count.to_i
      assert_equal 2, tag.training_count.to_i
      assert_equal 0, tag.classifier_count.to_i
    end
  
    it "is properly calculated for subscribed tags" do
      Tag.delete_all

      u = users(:quentin)
      fi1 = FeedItem.find(1)
      fi2 = FeedItem.find(4)
      peerworks = Tag(u, 'peerworks')
      test = Tag(u, 'test')
      tag = Tag(u, 'tag')
      Tagging.create(:user => u, :feed_item => fi1, :tag => peerworks)
      Tagging.create(:user => u, :feed_item => fi2, :tag => peerworks)
      Tagging.create(:user => u, :feed_item => fi1, :tag => test)
      TagSubscription.create(:tag_id => tag.id, :user_id => users(:aaron).id)

      tags = Tag.search(:user => users(:aaron), :own => true, :order => "name")
      assert_equal 1, tags.size
      assert_equal 'tag', tags[0].name
      assert_equal 0, tags[0].positive_count.to_i
    end
  end
  
  describe "specs" do
    it "filters items by search term" do
      user_1 = User.create! valid_user_attributes
      user_2 = User.create! valid_user_attributes(:login => "everman")
    
      tag_1 = Tag.create! valid_tag_attributes(:user_id => user_1.id, :name => "The best tag ever in the world", :comment => "")
      tag_2 = Tag.create! valid_tag_attributes(:user_id => user_1.id, :name => "Another Tag", :comment => "The second best tag ever")
      tag_3 = Tag.create! valid_tag_attributes(:user_id => user_2.id, :name => "My cool tag", :comment => "")
    
      tags = Tag.search(:user => user_1, :text_filter => "ever", :order => "id")
      tags.should == [tag_1, tag_2, tag_3]
    
      tags = Tag.search(:user => user_1, :text_filter => "world")
      tags.should == [tag_1]
    
      tags = Tag.search(:user => user_1, :text_filter => "second")
      tags.should == [tag_2]
    
      tags = Tag.search(:user => user_1, :text_filter => "man")
      tags.should == [tag_3]
    end
  
    it "does not clobber conditions when filtering by search term" do
      user_1 = User.create! valid_user_attributes
      user_2 = User.create! valid_user_attributes(:login => "everman")
    
      tag_1 = Tag.create! valid_tag_attributes(:user_id => user_1.id, :public => true, :name => "The best tag ever in the world", :comment => "")
      tag_2 = Tag.create! valid_tag_attributes(:user_id => user_1.id, :public => true, :name => "Another Tag", :comment => "The second best tag ever")
      tag_3 = Tag.create! valid_tag_attributes(:user_id => user_2.id, :name => "My cool tag", :comment => "")
    
      tags = Tag.search(:user => user_1, :text_filter => "ever", :conditions => { :public => true }, :order => "id")
      tags.should == [tag_1, tag_2]
    end
  
    it "should update it's timestamp when a new tag is created" do
      user = users(:quentin)
      feed_item = FeedItem.find(:first)
  
      tag = Tag.create! valid_tag_attributes(:user => user, :name => "No this tag is the best tag in the world")
      updated_on = tag.updated_on = Time.now.yesterday

      Tagging.create! :tag => tag, :user => user, :feed_item => feed_item, :strength => 1    
      tag.updated_on.should > updated_on
    end
  
    it "should update it's timestamp when a tag is deleted" do
      user = users(:quentin)
      feed_item = FeedItem.find(:first)
  
      tag = Tag.create! valid_tag_attributes(:user => user, :name => "No this tag is the best tag in the world")
      tagging = Tagging.create! :tag => tag, :user => user, :feed_item => feed_item, :strength => 1    
      updated_on = tag.updated_on = Time.now.yesterday
      tagging.destroy
      tag.updated_on.should > updated_on      
    end
    
    it "should delete classifier taggings" do
      user = User.create! valid_user_attributes
      feed_item_1 = valid_feed_item!
      feed_item_2 = valid_feed_item!
      tag = Tag.create! valid_tag_attributes(:user_id => user.id, :name => "mytag")
    
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
      @user = User.create! valid_user_attributes
      @tag = Tag.create! valid_tag_attributes(:user_id => @user.id, :name => 'mytag')
      # I need more items to tag
      valid_feed_item!
      valid_feed_item!
    end
    
    it "should return true if positive taggings less than 6" do
      FeedItem.find(:all).first(5).each do |i|
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
    fixtures :tags, :users
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

  it "should have an http://peerworks.org/classifier/edit link that refers to the classifier tagging resource" do
    @atom.links.detect {|l| l.rel == "#{CLASSIFIER_NS}/edit" }.should_not be_nil
    @atom.links.detect {|l| l.rel == "#{CLASSIFIER_NS}/edit" }.href.should == "http://winnow.mindloom.org/#{@user.login}/tags/#{@tag.name}/classifier_taggings.atom"
  end
  
  it "should be parseable by ratom" do
    lambda { Atom::Feed.load_feed(@atom.to_xml) }.should_not raise_error
  end
  
  it "should contain the full content for each item" do
    @atom.entries.each do |e|
      e.content.to_s.size.should > 0
    end
  end
end

describe Tag do
  fixtures :feed_items, :feed_item_contents
  describe "#to_atom" do
    CLASSIFIER_NS = 'http://peerworks.org/classifier'
    before(:all) do
      @user = User.create! valid_user_attributes
      @tag = Tag.create! valid_tag_attributes(:user_id => @user.id, :name => 'mytag', :last_classified_at => Time.now)
      @tag.taggings.create!(:feed_item => FeedItem.find(1), :user => @user, :strength => 1)
      @tag.taggings.create!(:feed_item => FeedItem.find(2), :user => @user, :strength => 1)
      @tag.taggings.create!(:feed_item => FeedItem.find(3), :user => @user, :strength => 0)
      @tag.taggings.create!(:feed_item => FeedItem.find(4), :user => @user, :strength => 0.95, :classifier_tagging => true)
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
      @atom.entries.detect {|e| e.id == "urn:peerworks.org:entry#1"}.should_not be_nil
      @atom.entries.detect {|e| e.id == "urn:peerworks.org:entry#2"}.should_not be_nil
      @atom.entries.detect {|e| e.id == "urn:peerworks.org:entry#4"}.should_not be_nil
    end
    
    it "should not contain any negatively tagged items" do
      @atom.entries.detect {|e| e.id == "urn:peerworks.org:entry#3"}.should be_nil
    end
    
    it "should have atom:category for the classifier example" do
      entry = @atom.entries.detect {|e| e.id == "urn:peerworks.org:entry#4"}
      entry.categories.first.should_not be_nil
    end
    
    it "should have the terms for the classifier example" do
      @atom.entries.detect {|e| e.id == "urn:peerworks.org:entry#4"}.categories.first.term.should == @tag.name
    end
    
    it "should have the scheme for the classifier example" do
      @atom.entries.detect {|e| e.id == "urn:peerworks.org:entry#4"}.categories.first.scheme.should == "http://winnow.mindloom.org/#{@user.login}/tags/"
    end
    
    it "should have the strength for the classifier example" do
      @atom.entries.detect {|e| e.id == "urn:peerworks.org:entry#4"}.categories.first[CLASSIFIER_NS, 'strength'].first.should == "0.95"
    end
    
    describe "with since" do
      it "should only return items with updated date after :since" do
        @atom = @tag.to_atom(:base_uri => 'http://winnow.mindloom.org', :since => Time.now)
        @atom.entries.detect {|e| e.id == "urn:peerworks.org:entry#1"}.should be_nil
      end
    end
    
    describe "with training only" do   
      before(:all) do
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
        @atom.entries.detect {|e| e.id == "urn:peerworks.org:entry#1"}.should_not be_nil
        @atom.entries.detect {|e| e.id == "urn:peerworks.org:entry#2"}.should_not be_nil
        @atom.entries.detect {|e| e.id == "urn:peerworks.org:entry#3"}.should_not be_nil
      end
    
      it "should not contain any classifier only tagged items" do
        @atom.entries.detect {|e| e.id == "urn:peerworks.org:entry#4"}.should be_nil
      end
            
      it "should have a classifier:negative-example for all negative examples" do
        @atom.entries.detect {|e| e.id == "urn:peerworks.org:entry#3"}.links.detect do |l| 
          l.rel == "http://peerworks.org/classifier/negative-example" && l.href == "http://winnow.mindloom.org/#{@user.login}/tags/#{@tag.name}"
        end.should_not be_nil
      end
        
      it "should have a atom:category for all positive examples" do
        @atom.entries.detect {|e| e.id == "urn:peerworks.org:entry#1"}.should have(1).categories
        @atom.entries.detect {|e| e.id == "urn:peerworks.org:entry#2"}.should have(1).categories
      end
      
      it "should have the tag name as the term for atom:categories" do
        @atom.entries.detect {|e| e.id == "urn:peerworks.org:entry#1"}.categories.first.term.should == @tag.name
        @atom.entries.detect {|e| e.id == "urn:peerworks.org:entry#2"}.categories.first.term.should == @tag.name
      end
    
      it "should have the users tag index as the scheme for the atom:categories" do
        @atom.entries.detect {|e| e.id == "urn:peerworks.org:entry#1"}.categories.first.scheme.should == "http://winnow.mindloom.org/#{@user.login}/tags/"
        @atom.entries.detect {|e| e.id == "urn:peerworks.org:entry#2"}.categories.first.scheme.should == "http://winnow.mindloom.org/#{@user.login}/tags/"
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
    @tag.classifier_taggings.find(:first, :conditions => ['feed_item_id = 3 and classifier_tagging = 1']).strength.should == 0.99
  end
end

describe Tag do
  describe "#create_taggings_from_atom" do      
    before(:each) do
      @user = User.create! valid_user_attributes
      @tag = Tag.create! valid_tag_attributes(:user => @user)
      @ut = @tag.taggings.create!(:user => @user, :feed_item => FeedItem.find(1), :classifier_tagging => false)
      @ct = @tag.taggings.create!(:user => @user, :feed_item => FeedItem.find(2), :classifier_tagging => true, :strength => 0.95)
      @updated_strength = 0.97
      @before_classifier_taggings_size = @tag.classifier_taggings.size
      @number_of_new_taggings = 1
      
      @atom = Atom::Feed.new do |f|
        f.entries << Atom::Entry.new do |e|
          e.id = "urn:peerworks.org:entry#3"
          e.categories << Atom::Category.new do |c|
            c.scheme = "http://winnow.mindloom.org/#{@user.login}/tags/"
            c.term = @tag.name
            c[CLASSIFIER_NS, 'strength'].as_attribute = true
            c[CLASSIFIER_NS, 'strength'] << ".99"
          end
        end
        f.entries << Atom::Entry.new do |e|
          e.id = "urn:peerworks.org:entry#2"
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
          e.id = "urn:peerworks.org:entry#123"
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
          e.id = "urn:peerworks.org:entry#4"
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
          e.id = "urn:peerworks.org:entry#4"          
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
      @user = User.create! valid_user_attributes
      @tag = Tag.create! valid_tag_attributes(:user => @user)
      @tag2 = Tag.create! valid_tag_attributes(:user => @user)
      @ut = @tag.taggings.create!(:user => @user, :feed_item => FeedItem.find(1), :classifier_tagging => false)
      @ct = @tag.taggings.create!(:user => @user, :feed_item => FeedItem.find(2), :classifier_tagging => true, :strength => 0.95)
      @ct2 = @tag2.taggings.create!(:user => @user, :feed_item => FeedItem.find(2), :classifier_tagging => true, :strength => 0.95)
            
      @atom = Atom::Feed.new do |f|
        f.entries << Atom::Entry.new do |e|
          e.id = "urn:peerworks.org:entry#3"
          e.categories << Atom::Category.new do |c|
            c.scheme = "http://winnow.mindloom.org/#{@user.login}/tags/"
            c.term = @tag.name
            c[CLASSIFIER_NS, 'strength'].as_attribute = true
            c[CLASSIFIER_NS, 'strength'] << "0.99"
          end
        end
        f.entries << Atom::Entry.new do |e|
          e.id = "urn:peerworks.org:entry#2"
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
  describe "from test/unit" do
    fixtures :users

    it "cant_create_duplicate_tags" do
      Tag.create!(:user => users(:quentin), :name => 'foo')
      Tag.new(:user => users(:quentin), :name => 'foo').should_not be_valid
    end
  
    it "cant_create_empty_tags" do
      Tag.new(:user => users(:quentin), :name => '').should_not be_valid
    end
  
    it "case_sensitive" do
      tag1 = Tag(users(:quentin), 'TAG1')
      tag2 = Tag(users(:quentin), 'tag1')
      assert_not_equal tag1, tag2
    end
  
    it "tag_function" do
      tag = Tag(users(:quentin), 'tag1')
      assert tag.is_a?(Tag)
      assert_equal 'tag1', tag.name
      assert !tag.new_record?    
      tag2 = Tag(users(:quentin), tag)
      assert_equal tag, tag2
    end
  
    it "tag_to_s_returns_name" do
      tag = Tag(users(:quentin), 'tag1')
      assert_equal('tag1', tag.to_s)
    end
  
    # it "tag_to_param_returns_name" do
    #   tag = Tag(users(:quentin), 'tag1')
    #   assert_equal('tag1', tag.to_param)
    # end
  
    it "sorting" do
      tag1 = Tag(users(:quentin), 'aaa')
      tag2 = Tag(users(:quentin), 'bbb')
      assert_equal([tag1, tag2], [tag1, tag2].sort)
      assert_equal([tag1, tag2], [tag2, tag1].sort)
    end
  
    it "sorting_is_case_insensitive" do
      tag1 = Tag(users(:quentin), 'aaa')
      tag2 = Tag(users(:quentin), 'Abb')
      assert_equal([tag1, tag2], [tag1, tag2].sort)
      assert_equal([tag1, tag2], [tag2, tag1].sort)
    end
  
    it "sorting_with_non_tag_raises_exception" do
      tag = Tag(users(:quentin), 'tag')
      assert_raise(ArgumentError) { tag <=> 42 }
    end
  
    it "two_tags_belonging_to_different_users_are_different" do
      assert_not_equal(Tag(users(:quentin), "tag"), Tag(users(:aaron), "tag"))    
    end
  
    it "copy_tag_to_self" do
      u = users(:quentin)
      tag = Tag(u, 'tag1')
      copy = Tag(u, 'copy of tag1')
      u.taggings.create(:feed_item => FeedItem.find(1), :tag => tag)
      u.taggings.create(:feed_item => FeedItem.find(2), :tag => tag)
      u.taggings.create(:feed_item => FeedItem.find(3), :tag => tag)
    
      tag.copy(copy)
      assert_equal(3, u.taggings.find_by_tag(copy).size)
      assert_equal(3, u.taggings.find_by_tag(tag).size)
    end
  
    it "copy_tag_to_another_user" do
      u = users(:quentin)
      u2 = users(:aaron)
      tag_quent = Tag(u, 'tag1')
      tag_aaron = Tag(u2, 'tag1')
      u.taggings.create(:feed_item => FeedItem.find(1), :tag => tag_quent)
      u.taggings.create(:feed_item => FeedItem.find(2), :tag => tag_quent)
      u.taggings.create(:feed_item => FeedItem.find(3), :tag => tag_quent)

      tag_quent.copy(tag_aaron)
      assert_equal(3, u.taggings.find_by_tag(tag_quent).size)
      assert_equal(3, u2.taggings.find_by_tag(tag_aaron).size)
    end
  
    it "copy_with_the_same_name_raises_error" do
      u = users(:quentin)
      tag = Tag(u, 'tag1')
      u.taggings.create(:feed_item => FeedItem.find(1), :tag => tag)
      u.taggings.create(:feed_item => FeedItem.find(2), :tag => tag)
      u.taggings.create(:feed_item => FeedItem.find(3), :tag => tag)
    
      assert_raise(ArgumentError) { tag.copy(tag) }
    end
  
    it "copy_to_other_user_when_tag_already_exists_raises_error" do
      u = users(:quentin)
      u2 = users(:aaron)
      u.taggings.create(:feed_item => FeedItem.find(1), :tag => Tag(u, 'tag1'))
      u2.taggings.create(:feed_item => FeedItem.find(2), :tag => Tag(u, 'tag1'))
    
      assert_raise(ArgumentError) { Tag(u, 'tag1').copy(Tag(u, 'tag1')) }
    end
  
    it "copying_a_tag_skips_classifier_taggings" do
      u = users(:quentin)
      tag = Tag(u, 'tag1')
      copy = Tag(u, 'copy of tag1')
      u.taggings.create(:feed_item => FeedItem.find(1), :tag => tag)
      u.taggings.create(:feed_item => FeedItem.find(2), :tag => tag, :classifier_tagging => true)
    
      tag.copy(copy)
      assert_equal(3, u.taggings.size)
      assert_equal(1, u.classifier_taggings.size)
    end
  
    it "copying_copies_the_tag_comment_and_bias" do
      user = users(:quentin)
      old_tag = Tag(user, 'old')
      old_tag.update_attributes :comment => "old tag comment", :bias => 0.9
      new_tag = Tag(user, 'new')
      new_tag.update_attributes :comment => "new tag comment"
        
      old_tag.copy(new_tag)
    
      new_tag.reload
    
      assert_equal 0.9, new_tag.bias
      assert_equal "old tag comment", new_tag.comment
    end
  
    it "merge_into_another_tag" do
      u = users(:quentin)
      old = Tag(u, 'old')
      new_tag = Tag(u, 'new')
    
      u.taggings.create(:feed_item => FeedItem.find(1), :tag => old)
      u.taggings.create(:feed_item => FeedItem.find(2), :tag => new_tag)
    
      old.merge(new_tag)
    
      assert_equal([], old.taggings)
      assert_equal([1, 2], new_tag.taggings.map(&:feed_item_id).sort)
    end
  
    it "merge_when_tag_exists_on_item" do
      u = users(:quentin)
      old = Tag(u, 'old')
      new_tag = Tag(u, 'new')
    
      u.taggings.create(:feed_item => FeedItem.find(1), :tag => old)
      u.taggings.create(:feed_item => FeedItem.find(1), :tag => new_tag)
    
      old.merge(new_tag)
    
      assert_equal([], old.taggings.map(&:feed_item_id))
      assert_equal([1], new_tag.taggings.map(&:feed_item_id))    
    end
  
    it "overwriting_a_tag" do
      user = users(:quentin)
      old_tag = Tag(user, 'old')
      old_tag.update_attributes :comment => "old tag comment", :bias => 0.9
      new_tag = Tag(user, 'new')
      new_tag.update_attributes :comment => "new tag comment"
    
      user.taggings.create(:feed_item => FeedItem.find(1), :tag => old_tag)
      user.taggings.create(:feed_item => FeedItem.find(2), :tag => new_tag)
    
      old_tag.overwrite(new_tag)
    
      new_tag.reload
    
      assert_equal [1], new_tag.taggings(:reload).map(&:feed_item_id)
      assert_equal 0.9, new_tag.bias
      assert_equal "old tag comment", new_tag.comment
    end
  end
end
