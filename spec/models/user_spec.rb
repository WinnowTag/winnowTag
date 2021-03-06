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

describe User do
  describe "associations" do
    before(:each) do
      @user = User.new
    end

    it "has many tag subscriptions" do
      @user.should have_many(:tag_subscriptions)
    end
  
    it "has many messages" do
      @user.should have_many(:messages)
    end
    
    it "has many comments" do
      @user.should have_many(:comments)
    end
  end
  
  describe "prototype" do
    it "marks all other users as non-prototypes when saving a prototype" do
      original_prototype = Generate.user!(:prototype => true)
      original_prototype.should be_prototype
      
      new_prototype = Generate.user!(:prototype => true)
      new_prototype.should be_prototype
      
      original_prototype.reload
      original_prototype.should_not be_prototype
    end

    it "saving the prototype doesn't unmark it as the prototype" do
      prototype = Generate.user!(:prototype => true)
      prototype.should be_prototype

      prototype.save
      prototype.reload
      prototype.should be_prototype
    end

    it "creating from a prototype activates the new user" do
      prototype = Generate.user!(:prototype => true)
      user = User.create_from_prototype(Generate.user_attributes(:activated_at => nil))
      user.reload.should be_active
    end
    
    it "creating from a prototype marks all system messages as read" do
      prototype = Generate.user!(:prototype => true)
      message = Message.create! :body => "some test message"
      user = User.create_from_prototype(Generate.user_attributes)
      Message.unread(user).for(user).should be_empty
    end
    
    it "creating from a prototype returns a new user record if the record was invalid" do
      prototype = Generate.user!(:prototype => true)
      user = User.create_from_prototype
      user.should be_new_record
    end
    
    it "creating from a prototype copies over tag subscriptions" do
      prototype = Generate.user!(:prototype => true)
      prototype.tag_subscriptions.create!(:tag_id => 1)
      prototype.tag_subscriptions.create!(:tag_id => 2)
      
      user = User.create_from_prototype(Generate.user_attributes)
      user.should have(2).tag_subscriptions
      
      user.tag_subscriptions.first.tag_id.should == 1
      user.tag_subscriptions.last.tag_id.should == 2
    end
    
    it "creating from a prototype copies over tags" do
      feed_item1 = Generate.feed_item!
      feed_item2 = Generate.feed_item!
      
      prototype = Generate.user!(:prototype => true)
                  
      tag1 = prototype.tags.create!(:name => "Tag 1", :public => false, :bias => 1.2, :description => "Tag 1 Comment")
      tag1.taggings.create! :classifier_tagging => true, :strength => 1, :feed_item_id => feed_item1.id, :user_id => prototype.id
      tag2 = prototype.tags.create!(:name => "Tag 2", :public => true, :bias => 1.5, :description => "Tag 2 Comment")
      tag2.taggings.create! :classifier_tagging => false, :strength => 0, :feed_item_id => feed_item2.id, :user_id => prototype.id
      
      user = User.create_from_prototype(Generate.user_attributes)
      user.should have(2).tags
      
      user.tags.first.name.should == "Tag 1"
      user.tags.first.public.should == false
      user.tags.first.bias.should == 1.2
      user.tags.first.description.should == "Tag 1 Comment"

      user.tags.first.should have(1).taggings   
      user.tags.first.taggings.first.classifier_tagging.should == true
      user.tags.first.taggings.first.strength.should == 1
      user.tags.first.taggings.first.feed_item_id.should == feed_item1.id
      user.tags.first.taggings.first.user_id.should == user.id
      user.tags.first.taggings.first.tag_id.should == user.tags.first.id
      
      user.tags.last.name.should == "Tag 2"
      user.tags.last.public.should == true
      user.tags.last.bias.should == 1.5
      user.tags.last.description.should == "Tag 2 Comment"

      user.tags.last.should have(1).taggings
      user.tags.last.taggings.first.classifier_tagging.should == false
      user.tags.last.taggings.first.strength.should == 0
      user.tags.last.taggings.first.feed_item_id.should == feed_item2.id
      user.tags.last.taggings.first.user_id.should == user.id    
      user.tags.last.taggings.first.tag_id.should == user.tags.last.id
    end
  end
  
  describe "logging login" do 
    before(:each) do
      @user = Generate.user!
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
      @user = Generate.user!(:reminder_code => "some randome string", :reminder_expires_at => 2.days.from_now)
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
      @user = Generate.user!

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
      user1 = Generate.user!(:login => "mark")
      user2 = Generate.user!(:email => "mark@example.com")
      user3 = Generate.user!(:firstname => "mark")
      user4 = Generate.user!(:lastname => "mark")
      user5 = Generate.user!
      
      expected_users = [user1, user2, user3, user4]
      
      users = User.search :text_filter => "mark", :order => "id"
      users.should == expected_users
    end
    
    context "when ordering by name" do
      
      it "orders by last name, first name, login" do
        user2 = Generate.user!(:lastname => "Smith", :firstname => "Jon",  :login => "jonsmith")
        user1 = Generate.user!(:lastname => "Smith", :firstname => "John", :login => "jsmith")
        user3 = Generate.user!(:lastname => "Smith", :firstname => "Jon",  :login => "jonsmith2")
        user5 = Generate.user!(:lastname => nil,     :firstname => nil,    :login => "jroe")
        user4 = Generate.user!(:lastname => nil,     :firstname => nil,    :login => "jdoe")
        
        expected_users = [user4, user5, user1, user2, user3]

        users = User.search :order => "name"
        users.should == expected_users
      end
    end
  end
  
  describe '#changed_tags' do
    before(:each) do
      @user = Generate.user!
      @changed_tag = Generate.tag!(:user => @user, :last_classified_at => Time.now.yesterday.getutc)
      @unchanged_tag = Generate.tag!(:user => @user, :last_classified_at => Time.now.tomorrow.getutc)
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
      6.times { Generate.feed_item! }

      @user = Generate.user!
      @changed_tag_with_5 = Generate.tag!(:user => @user, :last_classified_at => Time.now.yesterday.getutc)
      @changed_tag_with_6 = Generate.tag!(:user => @user, :last_classified_at => Time.now.yesterday.getutc)
      @unchanged_tag = Generate.tag!(:user => @user, :last_classified_at => Time.now.tomorrow.getutc)
      
      FeedItem.all(:limit => 5).each do |i|
        @changed_tag_with_5.taggings.create!(:user => @user, :feed_item => i, :strength => 1)
      end.should have(5).feed_items
      FeedItem.all(:limit => 6).each do |i|
        @changed_tag_with_6.taggings.create!(:user => @user, :feed_item => i, :strength => 1)
      end.should have(6).feed_items
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
    before(:each) do
      # Re-enable password hashing which is stubbed out in spec_helper.rb
      User.rspec_reset
    end
    
    it "required login" do
      user = Generate.user(:login => nil)
      user.should have(1).error_on(:login)
    end

    it "requires password" do
      user = Generate.user(:password => "", :password_confirmation => "password")
      user.should_not be_valid
      user.errors.on(:password).should == ["is too short (minimum is 4 characters)", "doesn't match confirmation"]
    end

    it "requires password confirmation" do
      user = Generate.user(:password => "password", :password_confirmation => "")
      user.should_not be_valid
      user.errors.on(:password).should == "doesn't match confirmation"
    end

    it "requires matching password confirmation" do
      user = Generate.user(:password => "password", :password_confirmation => "other password")
      user.should_not be_valid
      user.errors.on(:password).should == "doesn't match confirmation"
    end

    it "does not change the password when the current password is blank" do
      user = Generate.user!
      user.update_attributes(:current_password => "", :password => 'new password', :password_confirmation => 'new password')
      user.should_not be_valid
      user.errors.on(:current_password).should == "is not correct"
    end

    it "does not change the password when the current password is wrong" do
      user = Generate.user!
      user.update_attributes(:current_password => "wrong password", :password => 'new password', :password_confirmation => 'new password')
      user.should_not be_valid
      user.errors.on(:current_password).should == "is not correct"
    end
    
    it "changes the password when the current password is correct" do
      user = Generate.user!
      user.update_attributes(:current_password => "password", :password => 'new password', :password_confirmation => 'new password')
      User.authenticate(user.login, 'new password').should == user
    end

    it "does not change tha password when not give a password" do
      user = Generate.user!
      user.update_attributes(:firstname => "johnny")
      User.authenticate(user.login, 'password').should == user
    end

    it "does not authenticate a user with the wrong password" do
      user = Generate.user!
      User.authenticate(user.login, 'wrong password').should be_nil
    end

    it "authenticates a user with the correct password" do
      user = Generate.user!
      User.authenticate(user.login, 'password').should == user
    end
  end
  
  describe "from test/unit" do
    it "should_be_owner_of_self" do
      u = Generate.user!
      assert u.has_role?('owner', u)
    end
    
    it "login allows alphanumberic, -, and _" do
      user = Generate.user(:login => "John-J_Doe")
      user.should be_valid
    end
    
    it "login does not allow characters other than alphanumberic, -, and _" do
      user = Generate.user(:login => "john@example.com")
      user.should have(1).error_on(:login)
    end

    it "should_set_remember_token" do
      user = Generate.user!
      user.remember_me
      user.remember_token.should_not be_nil
      user.remember_token_expires_at.should_not be_nil
    end

    it "should_unset_remember_token" do
      user = Generate.user!

      user.remember_me
      user.remember_token.should_not be_nil
      user.remember_token_expires_at.should_not be_nil

      user.forget_me
      user.remember_token.should be_nil
      user.remember_token_expires_at.should be_nil
    end
   
    it "knows_that_given_user_is_not_subscribed_to_a_tag" do
      user = Generate.user!
      tag = Generate.tag!(:user => user)
    
      user.subscribed?(tag).should be_false
    end
  
    it "knows_that_given_user_is_subscribed_to_a_tag" do
      user = Generate.user!
      tag = Generate.tag!(:user => user)
      TagSubscription.create!(:tag => tag, :user => user)
    
      user.subscribed?(tag).should be_true
    end
  
    it "knows_feed_is_globally_excluded" do
      user = Generate.user!
      feed = Generate.feed!
      user.feed_exclusions.create!(:feed => feed)
    
      user.globally_excluded?(feed).should be_true
    end
  
    it "knows_feed_is_not_globally_excluded" do
      user = Generate.user!
      feed = Generate.feed!
    
      user.globally_excluded?(feed).should be_false
    end
  
    it "knows_tag_is_globally_excluded" do
      user = Generate.user!
      tag = Generate.tag!(:user => user)
      user.tag_exclusions.create!(:tag => tag)
    
      user.globally_excluded?(tag).should be_true
    end
  
    it "knows_tag_is_not_globally_excluded" do
      user = Generate.user!
      tag = Generate.tag!(:user => user)
    
      user.globally_excluded?(tag).should be_false
    end
  end
end

describe User, "email address validation" do
  
  before(:each) do
    @user = Generate.user
  end
  
  it "requires email" do
    @user.email = nil
    @user.should have_at_least(1).error_on(:email)
  end
  
  it "accepts basic address" do
    @user.email = "jdoe@example.com"
    @user.valid?
    @user.should have(0).errors_on(:email)
  end
  
  it "accepts address with underscore" do
    @user.email = "john_doe@example.com"
    @user.valid?
    @user.should have(0).errors_on(:email)
  end
  
  it "accepts address with dot" do
    @user.email = "john.doe@example.com"
    @user.valid?
    @user.should have(0).errors_on(:email)
  end
  
  it "accepts address with plus" do
    @user.email = "jdoe+wingnut@example.com"
    @user.valid?
    @user.should have(0).errors_on(:email)
  end
  
  it "accepts address with leading digits" do
    @user.email = "123jdoe@example.com"
    @user.valid?
    @user.should have(0).errors_on(:email)
  end
  
  it "rejects address with multiple @ symbols" do
    @user.email = "j@doe@example.com"
    @user.valid?
    @user.should have(1).error_on(:email)
  end
  
  it "rejects address with interspersed invalid characters" do
    @user.email = "%jd#o=&e@example.com"
    @user.valid?
    @user.should have(1).error_on(:email)
  end
  
end

describe User, '#email=' do
  
  it "strips quoted name from email" do
    user = User.new :email => '"John Von Doe" <jdoe@example.com>'
    user.email.should == "jdoe@example.com"
  end
  
  it "strips unquoted name from email" do
    user = User.new :email => 'John Von Doe <jdoe@example.com>'
    user.email.should == "jdoe@example.com"
  end
  
  context "when user lacks first or last name" do
    
    before(:each) do
      @user = User.new :email => '"John Von Doe" <jdoe@example.com>'
    end
    
    it "sets first name" do
      @user.firstname.should == "John"
    end
    
    it "sets last name" do
      @user.lastname.should == "Von Doe"
    end
    
  end
  
  context "when user already has first or last name" do
    
    before(:each) do
      @user = User.new :firstname => "Clark", :lastname => "Kent", :email => '"John Von Doe" <jdoe@example.com>'
    end
    
    it "does not set first name" do
      @user.firstname.should == "Clark"
    end
    
    it "does not set last name" do
      @user.lastname.should == "Kent"
    end
    
  end
  
end

describe User, '#email_address_with_name' do
  
  context "when first and last name are present" do
    
    before(:each) do
      @user = Generate.user! :firstname => "John", :lastname => "Doe", :email => "jdoe@example.com"
    end
    
    it "includes name in email address" do
      @user.email_address_with_name.should == '"John Doe" <jdoe@example.com>'
    end
    
  end
  
  context "when only first name is present" do
    
    before(:each) do
      @user = Generate.user! :firstname => "John", :lastname => nil, :email => "jdoe@example.com"
    end
    
    it "excludes name from email address" do
      @user.email_address_with_name.should == "jdoe@example.com"
    end
    
  end
  
  context "when only last name is present" do
    
    before(:each) do
      @user = Generate.user! :firstname => nil, :lastname => "Doe", :email => "jdoe@example.com"
    end
    
    it "excludes name from email address" do
      @user.email_address_with_name.should == "jdoe@example.com"
    end
    
  end
  
  context "when neither first nor last name is present" do
    
    before(:each) do
      @user = Generate.user! :firstname => nil, :lastname => nil, :email => "jdoe@example.com"
    end
    
    it "excludes name from email address" do
      @user.email_address_with_name.should == "jdoe@example.com"
    end
    
  end
  
end