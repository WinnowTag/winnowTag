require File.dirname(__FILE__) + '/../spec_helper'

describe Tag do
  it "Properly calculates tagging counts" do
    user_1 = User.create! valid_user_attributes
    user_2 = User.create! valid_user_attributes
    
    tag = Tag.create! valid_tag_attributes(:user_id => user_2.id, :public => true)
    tag_subscription = TagSubscription.create! :user_id => user_1.id, :tag_id => tag.id
    
    feed_item_1 = FeedItem.create! valid_feed_item_attributes
    feed_item_2 = FeedItem.create! valid_feed_item_attributes
    
    tagging_1 = Tagging.create! :tag_id => tag.id, :user_id => user_2.id, :feed_item_id => feed_item_1.id
    tagging_2 = Tagging.create! :tag_id => tag.id, :user_id => user_2.id, :feed_item_id => feed_item_2.id, :strength => 0.95, :classifier_tagging => true
    tagging_3 = Tagging.create! :tag_id => tag.id, :user_id => user_2.id, :feed_item_id => feed_item_2.id, :strength => 0
    
    tags = Tag.find_all_with_count(:subscribed_by => user_1, :subscriber => user_1)
    tags.should have(1).record
    
    tags.first.positive_count.should == "1"
    tags.first.negative_count.should == "1"
    tags.first.classifier_count.should == "1"
  end
  
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
    feed_item = FeedItem.create! valid_feed_item_attributes
    
    tag = Tag.create! valid_tag_attributes(:user_id => user.id, :name => "No this tag is the best tag in the world")
    updated_on = tag.updated_on
    sleep(1)
    Tagging.create! :tag_id => tag.id, :user_id => user.id, :feed_item_id => feed_item.id, :strength => 1    
    tag.reload
    tag.updated_on.should > updated_on
  end
  
  it "should delete classifier taggings" do
    user = User.create! valid_user_attributes
    feed_item_1 = FeedItem.create! valid_feed_item_attributes
    feed_item_2 = FeedItem.create! valid_feed_item_attributes
    tag = Tag.create! valid_tag_attributes(:user_id => user.id, :name => "mytag")
    
    t1 = Tagging.create! :user => user, :feed_item => feed_item_1, :tag => tag
    t2 = Tagging.create! :user => user, :feed_item => feed_item_2, :tag => tag, :classifier_tagging => true
    
    tag.taggings.should == [t1, t2]    
    tag.reload
    tag.delete_classifier_taggings!
    tag.taggings.should == [t1]
  end
  
  describe "from test/unit" do
    fixtures :users

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
  
    def test_has_many_tag_subscriptions
      assert_association Tag, :has_many, :tag_subscriptions    
    end
    
    def test_find_all_with_count
      u = users(:quentin)
      fi1 = FeedItem.find(1)
      fi2 = FeedItem.find(4)
      peerworks = Tag(u, 'peerworks')
      test = Tag(u, 'test')
      tag = Tag(u, 'tag')
      Tagging.create(:user => u, :feed_item => fi1, :tag => peerworks)
      Tagging.create(:user => u, :feed_item => fi2, :tag => peerworks)
      Tagging.create(:user => u, :feed_item => fi1, :tag => test)
      Tagging.create(:user => u, :feed_item => fi2, :tag => test, :strength => 0)

      tags = u.tags.find_all_with_count(:order => "tags.name")
      assert_equal 3, tags.size

      assert_equal 'peerworks', tags[0].name
      assert_equal 2, tags[0].positive_count.to_i
      assert_equal 0, tags[0].negative_count.to_i
      assert_equal 2, tags[0].training_count.to_i

      assert_equal 'tag', tags[1].name
      assert_equal 0, tags[1].positive_count.to_i
      assert_equal 0, tags[1].negative_count.to_i
      assert_equal 0, tags[1].training_count.to_i

      assert_equal 'test', tags[2].name
      assert_equal 1, tags[2].positive_count.to_i
      assert_equal 1, tags[2].negative_count.to_i
      assert_equal 2, tags[2].training_count.to_i
    end
  
    def test_find_all_subscribed_tags_with_count
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
end
