# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe User do
  fixtures :users, :feeds, :tags

  describe "associations" do
    before(:each) do
      @user = User.new
    end

    it "has many tag subscriptions" do
      @user.should have_many(:tag_subscriptions)
    end
    
    it "has many feed subscriptions" do
      @user.should have_many(:feed_subscriptions)
    end
    
    it "has many messages" do
      @user.should have_many(:messages)
    end
    
    it "has many feedbacks" do
      @user.should have_many(:feedbacks)
    end
    
    it "has many comments" do
      @user.should have_many(:comments)
    end
  end
  
  describe "prototype" do
    it "marks all other users as non-prototypes when saving a prototype" do
      original_prototype = User.create! valid_user_attributes(:prototype => true)
      original_prototype.should be_prototype
      
      new_prototype = User.create! valid_user_attributes(:prototype => true)
      new_prototype.should be_prototype
      
      original_prototype.reload
      original_prototype.should_not be_prototype
    end

    it "creating from a prototype activates the new user" do
      prototype = User.create! valid_user_attributes(:prototype => true)
      user = User.create_from_prototype(valid_user_attributes)
      user.should be_active
    end
    
    it "creating from a prototype marks all system messages as read" do
      prototype = User.create! valid_user_attributes(:prototype => true)
      Message.delete_all
      message = Message.create! :body => "some test message"
      user = User.create_from_prototype(valid_user_attributes)
      Message.find_unread_for_user_and_global(user).should be_empty
    end
    
    it "creating from a prototype returns a new user record if the record was invalid" do
      prototype = User.create! valid_user_attributes(:prototype => true)
      user = User.create_from_prototype
      user.should be_new_record
    end
    
    it "creating from a prototype copies over custom folders" do
      prototype = User.create! valid_user_attributes(:prototype => true)
      prototype.folders.create!(:name => "Big", :tag_ids => "1,2,3", :feed_ids => "4,5,6")
      prototype.folders.create!(:name => "Small", :tag_ids => "9", :feed_ids => "10")
      
      user = User.create_from_prototype(valid_user_attributes)
      user.should have(2).folders
      
      user.folders.first.name.should == "Big"
      user.folders.first.tag_ids.should == [1,2,3]
      user.folders.first.feed_ids.should == [4,5,6]

      user.folders.last.name.should == "Small"
      user.folders.last.tag_ids.should == [9]
      user.folders.last.feed_ids.should == [10]
    end
    
    it "creating from a prototype copies over feed subscriptions" do
      prototype = User.create! valid_user_attributes(:prototype => true)
      prototype.feed_subscriptions.create!(:feed_id => 1)
      prototype.feed_subscriptions.create!(:feed_id => 2)
      
      user = User.create_from_prototype(valid_user_attributes)
      user.should have(2).feed_subscriptions
      
      user.feed_subscriptions.first.feed_id.should == 1
      user.feed_subscriptions.last.feed_id.should == 2
    end
    
    it "creating from a prototype copies over tag subscriptions" do
      prototype = User.create! valid_user_attributes(:prototype => true)
      prototype.tag_subscriptions.create!(:tag_id => 1)
      prototype.tag_subscriptions.create!(:tag_id => 2)
      
      user = User.create_from_prototype(valid_user_attributes)
      user.should have(2).tag_subscriptions
      
      user.tag_subscriptions.first.tag_id.should == 1
      user.tag_subscriptions.last.tag_id.should == 2
    end
    
    it "creating from a prototype copies over tags" do
      prototype = User.create! valid_user_attributes(:prototype => true)
                  
      tag1 = prototype.tags.create!(:name => "Tag 1", :public => false, :bias => 1.2, :show_in_sidebar => true, :comment => "Tag 1 Comment")
      tag1.taggings.create! :classifier_tagging => true, :strength => 1, :feed_item_id => 1, :user_id => prototype.id
      tag2 = prototype.tags.create!(:name => "Tag 2", :public => true, :bias => 1.5, :show_in_sidebar => false, :comment => "Tag 2 Comment")
      tag2.taggings.create! :classifier_tagging => false, :strength => 0, :feed_item_id => 2, :user_id => prototype.id
      
      user = User.create_from_prototype(valid_user_attributes)
      user.should have(2).tags
      
      user.tags.first.name.should == "Tag 1"
      user.tags.first.public.should == false
      user.tags.first.bias.should == 1.2
      user.tags.first.show_in_sidebar.should == true
      user.tags.first.comment.should == "Tag 1 Comment"

      user.tags.first.should have(1).taggings   
      user.tags.first.taggings.first.classifier_tagging.should == true
      user.tags.first.taggings.first.strength.should == 1
      user.tags.first.taggings.first.feed_item_id.should == 1
      user.tags.first.taggings.first.user_id.should == user.id
      user.tags.first.taggings.first.tag_id.should == user.tags.first.id
      
      user.tags.last.name.should == "Tag 2"
      user.tags.last.public.should == true
      user.tags.last.bias.should == 1.5
      user.tags.last.show_in_sidebar.should == false
      user.tags.last.comment.should == "Tag 2 Comment"

      user.tags.last.should have(1).taggings
      user.tags.last.taggings.first.classifier_tagging.should == false
      user.tags.last.taggings.first.strength.should == 0
      user.tags.last.taggings.first.feed_item_id.should == 2
      user.tags.last.taggings.first.user_id.should == user.id    
      user.tags.last.taggings.first.tag_id.should == user.tags.last.id
    end
  end
  
  describe "logging login" do 
    before(:each) do
      @user = User.create! valid_user_attributes
      @time = Time.now
      
      @user.logged_in_at.should_not == @time
      @user.login!(@time)
    end

    it "updates the last login time" do
      @user.logged_in_at.should == @time
    end

    it "saves the last login time" do
      @user.logged_in_at.should == @time
    end
  end
  
  describe "logging reminder login" do 
    before(:each) do
      @user = User.create! valid_user_attributes(:reminder_code => "some randome string", :reminder_expires_at => 2.days.from_now)
      @time = Time.now
      
      @user.logged_in_at.should_not == @time
      @user.reminder_code.should_not be_nil
      @user.reminder_expires_at.should_not be_nil
      @user.reminder_login!(@time)
    end

    it "updates the last login time" do
      @user.logged_in_at.should == @time
    end

    it "saves the last login time" do
      @user.logged_in_at.should == @time
    end

    it "clears the reminder coder" do
      @user.reminder_code.should be_nil
    end

    it "clear the reminder expiration time" do
      @user.reminder_expires_at.should be_nil
    end
  end
  
  describe "enabling reminder login" do 
    before(:each) do
      @user = User.create! valid_user_attributes

      @user.reminder_code.should be_nil
      @user.reminder_expires_at.should be_nil
      @user.enable_reminder!
    end

    it "sets the reminder coder" do
      @user.reminder_code.should_not be_nil
    end

    it "sets the reminder expiration time" do
      @user.reminder_expires_at.should_not be_nil
    end
  end
  
  describe "searching" do
    it "can find users by login, email, firstname, or lastname" do
      user1 = User.create! valid_user_attributes(:login => "mark")
      user2 = User.create! valid_user_attributes(:email => "mark@example.com")
      user3 = User.create! valid_user_attributes(:firstname => "mark")
      user4 = User.create! valid_user_attributes(:lastname => "mark")
      user5 = User.create! valid_user_attributes
      
      expected_users = [user1, user2, user3, user4]
      
      users = User.search :text_filter => "mark", :order => "id"
      users.should == expected_users
    end
  end
  
  describe '#changed_tags' do
    before(:each) do
      @user = User.create! valid_user_attributes      
      @changed_tag = @user.tags.create!(valid_tag_attributes(:last_classified_at => Time.now.yesterday.getutc))
      @unchanged_tag = @user.tags.create!(valid_tag_attributes(:last_classified_at => Time.now.tomorrow.getutc))
    end
    
    it "should return tag with updated_on later than last_classified" do
      @user.changed_tags.should include(@changed_tag)
    end
    
    it "should not return the unchanged tag" do
      @user.changed_tags.should_not include(@unchanged_tag)
    end
  end
  
  describe '#potentially_undertrained_changed_tags' do
    before(:each) do
      valid_feed_item!
      valid_feed_item!
      @user = User.create! valid_user_attributes      
      @changed_tag_with_5 = @user.tags.create!(valid_tag_attributes(:last_classified_at => Time.now.yesterday.getutc))
      @changed_tag_with_6 = @user.tags.create!(valid_tag_attributes(:last_classified_at => Time.now.yesterday.getutc))
      @unchanged_tag = @user.tags.create!(valid_tag_attributes(:last_classified_at => Time.now.tomorrow.getutc))
      
      FeedItem.find(:all).first(5).each do |i|
        @changed_tag_with_5.taggings.create!(:user => @user, :feed_item => i, :strength => 1)
      end
      FeedItem.find(:all).each do |i|
        @changed_tag_with_6.taggings.create!(:user => @user, :feed_item => i, :strength => 1)
      end
    end
    
    it "should not return an unchanged tag" do
      @user.potentially_undertrained_changed_tags.should_not include(@unchanged_tag)
    end
    
    it "should not return a changed tag which is not potentially undertrained" do
      @user.potentially_undertrained_changed_tags.should_not include(@changed_tag_with_6)
    end
    
    it "should return a changed tag with is potentially undertrained" do
      @user.potentially_undertrained_changed_tags.should include(@changed_tag_with_5)
    end
  end
  
  describe "password" do
    fixtures :users, :feed_items
    
    before(:each) do
      # Re-enable password hashing which is stubbed out in spec_helper.rb
      User.rspec_reset
    end
    
    it "should_require_login" do
      user = User.new valid_user_attributes(:login => nil)
      user.should have(1).error_on(:login)
    end

    it "should_require_password" do
      user = User.new valid_user_attributes(:password => nil)
      user.should have(2).errors_on(:password)
    end
    
    it "should_reset_password" do
      users(:quentin).update_attributes(:password => 'new password', :password_confirmation => 'new password')
      assert_equal users(:quentin), User.authenticate('quentin', 'new password')
    end

    it "should_not_rehash_password" do
      users(:quentin).update_attributes(:login => 'quentin2')
      assert_equal users(:quentin), User.authenticate('quentin2', 'test')
    end

    it "should_authenticate_user" do
      assert_equal users(:quentin), User.authenticate('quentin', 'test')
    end
  end
  
  describe "from test/unit" do
    fixtures :users, :feed_items
    
    it "should_be_owner_of_self" do
      u = create_user
      assert u.has_role?('owner', u)
    end
  
    it "should_require_email" do
      user = User.new valid_user_attributes(:email => nil)
      user.should have(1).error_on(:email)
    end

    it "should_set_remember_token" do
      users(:quentin).remember_me
      assert_not_nil users(:quentin).remember_token
      assert_not_nil users(:quentin).remember_token_expires_at
    end

    it "should_unset_remember_token" do
      users(:quentin).remember_me
      assert_not_nil users(:quentin).remember_token
      users(:quentin).forget_me
      assert_nil users(:quentin).remember_token
    end
   
    it "tagging_statistics" do
      u = users(:quentin)
      pw = Tag(u, 'peerworks')
      tag = Tag(u, 'tag')

      assert_equal 0, u.tagging_percentage
      assert_nil u.last_tagging_on
      assert_equal 0, u.average_taggings_per_item
      assert_equal 0, u.number_of_tagged_items

      assert Tagging.create(:user => u, :feed_item => FeedItem.find(1), :tag => pw)
      assert last = Tagging.create(:user => u, :feed_item => FeedItem.find(2), :tag => pw)

      assert_equal 50, u.tagging_percentage
      assert_equal last.created_on.to_s, u.last_tagging_on.to_s
      assert_equal 1, u.average_taggings_per_item
      assert_equal 2, u.number_of_tagged_items

      Tagging.create(:user => u, :feed_item => FeedItem.find(1), :tag => tag)
      last = Tagging.create(:user => u, :feed_item => FeedItem.find(2), :tag => tag)

      assert_equal 50, u.tagging_percentage
      assert_equal last.created_on.to_s, u.last_tagging_on.to_s
      assert_equal 2, u.average_taggings_per_item
      assert_equal 2, u.number_of_tagged_items

      Tagging.create(:user => u, :feed_item => FeedItem.find(3), :tag => pw)
      last = Tagging.create(:user => u, :feed_item => FeedItem.find(4), :tag => pw)

      assert_equal 100, u.tagging_percentage
      assert_equal last.created_on.to_s, u.last_tagging_on.to_s
      assert_equal 1.5, u.average_taggings_per_item
      assert_equal 4, u.number_of_tagged_items

      User.find_by_login('quentin').taggings.clear
      assert_equal 0, u.tagging_percentage
      assert_nil u.last_tagging_on
      assert_equal 0, u.average_taggings_per_item
      assert_equal 0, u.number_of_tagged_items
    end
  
    it "knows_that_given_user_is_not_subscribed_to_a_tag" do
      current_user = users(:quentin)
      tag = Tag(current_user, 'hockey')
      TagSubscription.delete_all
    
      assert !current_user.subscribed?(tag)
    end
  
    it "knows_that_given_user_is_subscribed_to_a_tag" do
      current_user = users(:quentin)
      tag = Tag(current_user, 'hockey')
      TagSubscription.create! :tag_id => tag.id, :user_id => current_user.id
    
      assert current_user.subscribed?(tag)
    end
  
    it "knows_that_given_user_is_not_subscribed_to_a_feed" do
      current_user = users(:quentin)
      feed = Feed.find(:first)
      FeedSubscription.delete_all
    
      assert !current_user.subscribed?(feed)
    end
  
    it "knows_that_given_user_is_subscribed_to_a_feed" do
      current_user = users(:quentin)
      feed = Feed.find(:first)
      FeedSubscription.create! :feed_id => feed.id, :user_id => current_user.id
    
      assert current_user.subscribed?(feed)
    end
  
    it "knows_feed_is_globally_excluded" do
      current_user = users(:quentin)
      feed = Feed.create! :via => "http://news.google.com"
      current_user.feed_exclusions.create! :feed_id => feed.id
    
      assert current_user.globally_excluded?(feed)
    end
  
    it "knows_feed_is_not_globally_excluded" do
      current_user = users(:quentin)
      feed = Feed.create! :via => "http://news.google.com"
    
      assert !current_user.globally_excluded?(feed)
    end
  
    it "knows_tag_is_globally_excluded" do
      current_user = users(:quentin)
      tag = Tag(current_user, 'demo')
      current_user.tag_exclusions.create! :tag_id => tag.id
    
      assert current_user.globally_excluded?(tag)
    end
  
    it "knows_tag_is_not_globally_excluded" do
      current_user = users(:quentin)
      tag = Tag(current_user, 'demo')
    
      assert !current_user.globally_excluded?(tag)
    end
  
    it "update_feed_state_moves_feed_subscriptions_when_feed_is_a_duplicate" do
      current_user = users(:quentin)
      feed = Feed.create! :via => 'http://news.google.com'
      duplicate = Feed.new :via => 'http://google.com/news'
      duplicate.id = 1001
      duplicate.duplicate = feed
      duplicate.save!
    
      # create a subscription to the duplicate
      sub = FeedSubscription.create! :feed_id => duplicate.id, :user_id => current_user.id

      assert current_user.subscribed?(duplicate)
      assert !current_user.subscribed?(feed)

      current_user.update_feed_state(duplicate)
    
      assert !current_user.subscribed?(duplicate)
      assert current_user.subscribed?(feed)
    end
  
    it "update_feed_state_does_nothing_with_feed_is_not_a_duplicate" do
      current_user = users(:quentin)
      feed = Feed.create! :via => 'http://news.google.com'
      # create a subscription to the feed
      sub = FeedSubscription.create! :feed_id => feed.id, :user_id => current_user.id
    
      current_user.update_feed_state(feed)
    
      assert current_user.subscribed?(feed)
    end
    
  private
    def create_user(options = {})
      User.create!({ :login => 'quire', 
                    :email => 'quire@example.com', 
                    :password => 'quire', 
                    :firstname => 'Qu', 
                    :lastname => 'Ire',
                    :password_confirmation => 'quire' }.merge(options))
    end
  end
end