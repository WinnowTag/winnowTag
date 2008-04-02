require File.dirname(__FILE__) + '/../spec_helper'

describe Tag do
  fixtures :users, :feed_items
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

      tags = u.tags.find_all_with_count(:order => "tags.name")
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

      tags = Tag.find_all_with_count(:order => "tags.name", :subscribed_by => users(:aaron))
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
    
      tags = Tag.find_all_with_count(:search_term => "ever")
      tags.should == [tag_1, tag_2, tag_3]
    
      tags = Tag.find_all_with_count(:search_term => "world")
      tags.should == [tag_1]
    
      tags = Tag.find_all_with_count(:search_term => "second")
      tags.should == [tag_2]
    
      tags = Tag.find_all_with_count(:search_term => "man")
      tags.should == [tag_3]
    end
  
    it "does not clobber conditions when filtering by search term" do
      user_1 = User.create! valid_user_attributes
      user_2 = User.create! valid_user_attributes(:login => "everman")
    
      tag_1 = Tag.create! valid_tag_attributes(:user_id => user_1.id, :public => true, :name => "The best tag ever in the world", :comment => "")
      tag_2 = Tag.create! valid_tag_attributes(:user_id => user_1.id, :public => true, :name => "Another Tag", :comment => "The second best tag ever")
      tag_3 = Tag.create! valid_tag_attributes(:user_id => user_2.id, :name => "My cool tag", :comment => "")
    
      tags = Tag.find_all_with_count(:search_term => "ever", :conditions => { :public => true })
      tags.should == [tag_1, tag_2]
    end
  
    it "should update it's timestamp when a new tag is created" do
      user = User.create! valid_user_attributes
      feed_item = valid_feed_item!
    
      tag = Tag.create! valid_tag_attributes(:user_id => user.id, :name => "No this tag is the best tag in the world")
      updated_on = tag.updated_on
      sleep(1)
      Tagging.create! :tag_id => tag.id, :user_id => user.id, :feed_item_id => feed_item.id, :strength => 1    
      tag.reload
      tag.updated_on.should > updated_on
    end
    
    it "should update it's timestamp when a tag is deleted" do
      user = User.create! valid_user_attributes
      feed_item = valid_feed_item!
    
      tag = Tag.create! valid_tag_attributes(:user_id => user.id, :name => "No this tag is the best tag in the world")
      tagging = Tagging.create! :tag_id => tag.id, :user_id => user.id, :feed_item_id => feed_item.id, :strength => 1    
      tag.reload
      updated_on = tag.updated_on
      sleep(1)
      tagging.destroy
      tag.reload
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
  
  describe '.to_atomsvc' do
    before(:each) do
      @atomsvc = Tag.to_atomsvc(:base_uri => 'http://winnow.mindloom.org')
    end
    
    it "should return an Atom::Pub:Service" do
      @atomsvc.should be_an_instance_of(Atom::Pub::Service)
    end
    
    it "should have a single workspace" do
      @atomsvc.should have(1).workspaces
    end
    
    it "should have 'Tags' as the title of the workspace" do
      @atomsvc.workspaces.first.title.should == 'Tags'
    end
    
    it "should have a collection for each tag" do
      @atomsvc.workspaces.first.should have(Tag.count).collections
    end      

    it "should have some tags" do
      @atomsvc.workspaces.first.should have_at_least(1).collections
    end
    
    it "should have a title in each collection" do
      @atomsvc.workspaces.first.collections.each do |c|
        c.title.should_not be_nil
      end
    end
      
    it "should have an empty app:accept element in each collection" do
      @atomsvc.workspaces.first.collections.each do |c|
        c.accepts.should == ['']
      end
    end
    
    it "should have a url for each collection" do
      @atomsvc.workspaces.first.collections.each do |c|
        c.href.should_not be_nil
      end
    end
    
    it "should have :base_uri/tags/:id for the url for each collection" do
      @atomsvc.workspaces.first.collections.each do |c|
        c.href.should match(%r{http://winnow.mindloom.org/tags/\d+})
      end
    end
    
    it "should be parseable by ratom" do
      lambda { Atom::Pub::Service.load_service(@atomsvc.to_xml) }.should_not raise_error
    end
  end
  
  describe "#to_atom with training only" do
    CLASSIFIER_NS = 'http://peerworks.org/classifier'
    before(:each) do
      @user = User.create! valid_user_attributes
      @tag = Tag.create! valid_tag_attributes(:user_id => @user.id, :name => 'mytag', :last_classified_at => Time.now)
      @tag.taggings.create!(:feed_item => FeedItem.find(1), :user => @user, :strength => 1)
      @tag.taggings.create!(:feed_item => FeedItem.find(2), :user => @user, :strength => 1)
      @tag.taggings.create!(:feed_item => FeedItem.find(3), :user => @user, :strength => 0)
      @tag.taggings.create!(:feed_item => FeedItem.find(4), :user => @user, :strength => 0.95, :classifier_tagging => true)
      @atom = @tag.to_atom(:training_only => true, :base_uri => 'http://winnow.mindloom.org')
    end
    
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
      @atom.id.should == "http://winnow.mindloom.org/tags/#{@tag.id}"
    end
    
    it "should have an http://peerworks.org/classifier/edit link that refers to the classifier tagging resource" do
      @atom.links.detect {|l| l.rel == "#{CLASSIFIER_NS}/edit" }.should_not be_nil
      @atom.links.detect {|l| l.rel == "#{CLASSIFIER_NS}/edit" }.href.should == "http://winnow.mindloom.org/tags/#{@tag.id}/classifier_taggings"
    end
    
    it "should have a self link" do
      @atom.links.detect {|l| l.rel == "self" }.should_not be_nil
      @atom.links.detect {|l| l.rel == "self" }.href.should == "http://winnow.mindloom.org/tags/#{@tag.id}"
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
    
    it "should contain the full content for each item" do
      @atom.entries.each do |e|
        e.content.to_s.size.should > 0
      end
    end
    
    it "should have either classifier:positive-example or classifier:negative-example elements for all items" do
      @atom.entries.each do |e|
        (e[CLASSIFIER_NS, 'positive-example'] + e[CLASSIFIER_NS, 'negative-example']).size.should == 1
      end
    end
    
    it "should have a classifier:negative-example for all negative examples" do
      @atom.entries.detect {|e| e.id == "urn:peerworks.org:entry#1"}[CLASSIFIER_NS, 'positive-example'].should_not be_empty
      @atom.entries.detect {|e| e.id == "urn:peerworks.org:entry#2"}[CLASSIFIER_NS, 'positive-example'].should_not be_empty
    end
        
    it "should have a classifier:positive-example for all positive examples" do
      @atom.entries.detect {|e| e.id == "urn:peerworks.org:entry#3"}[CLASSIFIER_NS, 'negative-example'].should_not be_empty
    end
      
    
    it "should be parseable by ratom" do
      lambda { Atom::Feed.load_feed(@atom.to_xml) }.should_not raise_error
    end
  end
  
  describe "from test/unit" do
    fixtures :users

    before(:each) do
      Tag.delete_all
    end

    def test_cant_create_duplicate_tags
      Tag.create!(:user => users(:quentin), :name => 'foo')
      Tag.new(:user => users(:quentin), :name => 'foo').should_not be_valid
    end
  
    def test_cant_create_empty_tags
      Tag.new(:user => users(:quentin), :name => '').should_not be_valid
    end
  
    def test_case_sensitive
      tag1 = Tag(users(:quentin), 'TAG1')
      tag2 = Tag(users(:quentin), 'tag1')
      assert_not_equal tag1, tag2
    end
  
    def test_tag_function
      tag = Tag(users(:quentin), 'tag1')
      assert tag.is_a?(Tag)
      assert_equal 'tag1', tag.name
      assert !tag.new_record?    
      tag2 = Tag(users(:quentin), tag)
      assert_equal tag, tag2
    end
  
    def test_tag_to_s_returns_name
      tag = Tag(users(:quentin), 'tag1')
      assert_equal('tag1', tag.to_s)
    end
  
    # def test_tag_to_param_returns_name
    #   tag = Tag(users(:quentin), 'tag1')
    #   assert_equal('tag1', tag.to_param)
    # end
  
    def test_sorting
      tag1 = Tag(users(:quentin), 'aaa')
      tag2 = Tag(users(:quentin), 'bbb')
      assert_equal([tag1, tag2], [tag1, tag2].sort)
      assert_equal([tag1, tag2], [tag2, tag1].sort)
    end
  
    def test_sorting_is_case_insensitive
      tag1 = Tag(users(:quentin), 'aaa')
      tag2 = Tag(users(:quentin), 'Abb')
      assert_equal([tag1, tag2], [tag1, tag2].sort)
      assert_equal([tag1, tag2], [tag2, tag1].sort)
    end
  
    def test_sorting_with_non_tag_raises_exception
      tag = Tag(users(:quentin), 'tag')
      assert_raise(ArgumentError) { tag <=> 42 }
    end
  
    def test_two_tags_belonging_to_different_users_are_different
      assert_not_equal(Tag(users(:quentin), "tag"), Tag(users(:aaron), "tag"))    
    end
  
    def test_copy_tag_to_self
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
  
    def test_copy_tag_to_another_user
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
  
    def test_copy_with_the_same_name_raises_error
      u = users(:quentin)
      tag = Tag(u, 'tag1')
      u.taggings.create(:feed_item => FeedItem.find(1), :tag => tag)
      u.taggings.create(:feed_item => FeedItem.find(2), :tag => tag)
      u.taggings.create(:feed_item => FeedItem.find(3), :tag => tag)
    
      assert_raise(ArgumentError) { tag.copy(tag) }
    end
  
    def test_copy_to_other_user_when_tag_already_exists_raises_error
      u = users(:quentin)
      u2 = users(:aaron)
      u.taggings.create(:feed_item => FeedItem.find(1), :tag => Tag(u, 'tag1'))
      u2.taggings.create(:feed_item => FeedItem.find(2), :tag => Tag(u, 'tag1'))
    
      assert_raise(ArgumentError) { Tag(u, 'tag1').copy(Tag(u, 'tag1')) }
    end
  
    def test_copying_a_tag_skips_classifier_taggings
      u = users(:quentin)
      tag = Tag(u, 'tag1')
      copy = Tag(u, 'copy of tag1')
      u.taggings.create(:feed_item => FeedItem.find(1), :tag => tag)
      u.taggings.create(:feed_item => FeedItem.find(2), :tag => tag, :classifier_tagging => true)
    
      tag.copy(copy)
      assert_equal(3, u.taggings.size)
      assert_equal(1, u.classifier_taggings.size)
    end
  
    def test_copying_copies_the_tag_comment_and_bias
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
  
    def test_merge_into_another_tag
      u = users(:quentin)
      old = Tag(u, 'old')
      new_tag = Tag(u, 'new')
    
      u.taggings.create(:feed_item => FeedItem.find(1), :tag => old)
      u.taggings.create(:feed_item => FeedItem.find(2), :tag => new_tag)
    
      old.merge(new_tag)
    
      assert_equal([], old.taggings)
      assert_equal([1, 2], new_tag.taggings.map(&:feed_item_id).sort)
    end
  
    def test_merge_when_tag_exists_on_item
      u = users(:quentin)
      old = Tag(u, 'old')
      new_tag = Tag(u, 'new')
    
      u.taggings.create(:feed_item => FeedItem.find(1), :tag => old)
      u.taggings.create(:feed_item => FeedItem.find(1), :tag => new_tag)
    
      old.merge(new_tag)
    
      assert_equal([], old.taggings.map(&:feed_item_id))
      assert_equal([1], new_tag.taggings.map(&:feed_item_id))    
    end
  
    def test_overwriting_a_tag
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
