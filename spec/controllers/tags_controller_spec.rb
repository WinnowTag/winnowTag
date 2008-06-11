# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../spec_helper'

shared_examples_for 'conditional GET of tag' do
  it "should return not modified for show if if_modified after as updated on and last classified" do
    time = Time.now.yesterday
    @tag.stub!(:updated_on).and_return(time)
    @tag.stub!(:last_classified_at).and_return(time)    
    @tag.should_receive(:to_atom).never
    request.env['HTTP_IF_MODIFIED_SINCE'] = Time.now.httpdate
  
    get @action, :tag_name => @tag.name, :user => 'quentin'
    response.code.should == '304'
  end

  it "should return 200 for show if if_modified_since older than updated on" do      
    @tag.stub!(:last_classified_at).and_return(Time.now.yesterday.yesterday)
    request.env['HTTP_IF_MODIFIED_SINCE'] = Time.now.yesterday.httpdate
  
    get @action, :tag_name => @tag.name, :user => 'quentin'
    response.should be_success
  end
end

shared_examples_for 'tag access controls' do
  it "anyone can access feeds if the tag is public" do
    @tag.stub!(:public?).and_return(true)
    login_as(nil)
    get @action, :user => 'quentin', :tag_name => @tag.name, :format => "atom"
    response.should be_success
  end
  
  it "should prevent anyone accessing private tags" do
    @tag.stub!(:public?).and_return(false)
    login_as(nil)
    get @action, :user => 'quentin', :tag_name => @tag.name, :format => "atom"
    response.code.should == "401"
  end
  
  it "should return 404 for only style URLs when no one is logged in" do
    login_as(nil)
    get @action, :id => @tag.id
    response.code.should == "404"
  end
  
  it "should allow the owner to access private tags" do
    @tag.stub!(:public?).and_return(false)
    login_as(:quentin)
    get @action, :user => 'quentin', :tag_name => @tag.name, :format => "atom"
    response.code.should == "200"
  end
  
  it "should allow local requests to access private tags regardless of login" do
    @tag.stub!(:public?).and_return(false)
    login_as(nil)
    @controller.stub!(:local_request?).and_return(true)
    get @action, :user => 'quentin', :tag_name => @tag.name, :format => "atom"
    response.code.should == "200"
  end
end

describe TagsController do
  fixtures :users, :feed_items

  before(:each) do
    Tag.delete_all
    login_as(:quentin)

  end
  
  describe "create" do
    before(:each) do
      @tag = Tag(users(:quentin), 'tag')
      @tagging = Tagging.create(:user => users(:quentin), :tag => @tag, :feed_item => FeedItem.find(1))
    end

    it "copies named tag" do
      users(:quentin).taggings.create(:tag => @tag, :feed_item => FeedItem.find(1))
      assert_difference("users(:quentin).tags.count") do
        post :create, :copy => @tag, :name => "tag - copy"
        assert_response :success
        assert_equal("tag successfully copied to tag - copy", flash[:notice])
      end
      assert users(:quentin).tags.find(:first, :conditions => ['tags.name = ?', 'tag - copy'])
      assert_equal(2, users(:quentin).taggings.size)
    end
  
    it "prompts the user to overwrite when copying to an existing tag" do
      tag2 = Tag(users(:quentin), 'tag2')
    
      post :create, :copy => @tag, :name => "tag2"
      assert_response :success
    
      assert_match /confirm/, response.body
    end
  
    it "overwrites an existing tag when overwrite is set to true" do
      tag2 = Tag(users(:quentin), 'tag2')
    
      feed_item_1 = FeedItem.find(1)
      feed_item_2 = FeedItem.find(2)
    
      users(:quentin).taggings.create(:tag => @tag, :feed_item => feed_item_1)
      users(:quentin).taggings.create(:tag => tag2, :feed_item => feed_item_2)

      assert_equal [feed_item_1], @tag.taggings.map(&:feed_item)
      assert_equal [feed_item_2], tag2.taggings.map(&:feed_item)

      assert_difference("users(:quentin).tags.count", 0) do
        post :create, :copy => @tag, :name => "tag2", :overwrite => "true"
        assert_response :success
        assert_equal("tag successfully copied to tag2", flash[:notice])
      end

      assert_equal [feed_item_1], tag2.taggings(:reload).map(&:feed_item)
    end
    
    it "can create a new tag" do
      assert_difference "Tag.count" do
        post :create, :name => "new tag"
      end
    end
  end
  
  describe 'GET /' do
    it "index" do
      get :index
    end
  end
  
  describe "index with Accept: application/atom+xml" do
    before(:each) do
      Tag.stub!(:maximum).with(:created_on).and_return(Time.now)
      Tag.stub!(:to_atom).with(:base_uri => "http://test.host:80").and_return(Atom::Feed.new)
    end
    
    it "should call Tag.to_atom" do
      Tag.should_receive(:to_atom).with(:base_uri => "http://test.host:80").and_return(Atom::Feed.new)
      get :index, :format => 'atom'      
    end
    
    it "should be successful" do
      accept('application/atom+xml')
      get :index
      response.should be_success
    end
        
    it "should have application/atom+xml as the content type" do
      accept('application/atom+xml')
      get :index
      response.content_type.should == "application/atom+xml"
    end
    
    it "should have application/atom+xml as the content type when :format is atom" do
      get :index, :format => 'atom'
      response.content_type.should == "application/atom+xml"
    end
    
    it "should have the atom content" do
      get :index, :format => 'atom'
      response.body.should match(%r{<feed})
    end
    
    it "should respond with a 304 if there are no new tags since HTTP_IF_MODIFIED_SINCE" do
      Tag.should_receive(:maximum).with(:created_on).and_return(Time.now.yesterday)
      Tag.should_not_receive(:to_atom).with(:base_uri => "http://test.host:80")
      request.env['HTTP_IF_MODIFIED_SINCE'] = Time.now.httpdate
      get :index, :format => 'atom'
      response.code.should == "304"
    end
    
    it "should responde with a 200 if there are new tags since HTTP_IF_MODIFIED_SINCE" do
      request.env['HTTP_IF_MODIFIED_SINCE'] = 30.days.ago.httpdate
      get :index, :format => 'atom'
      response.code.should == "200"
    end
    
    it "should not require a login for local requests" do
      login_as(nil)
      @controller.stub!(:local_request?).and_return(true)
      get :index, :format => 'atom'
      response.should be_success
    end    
  end
  
  describe "show" do
    before(:each) do
      @action = "show" # for 'conditional GET of tag'
      mock_user_for_controller
      @tag = mock_model(Tag, :updated_on => Time.now, :last_classified_at => Time.now, :name => 'Tag23', :public? => true, :user_id => @user.id)
      @tag.stub!(:to_atom).and_return(Atom::Feed.new)
      @mock_tags = mock('tags')
      @mock_tags.stub!(:find_by_name).and_return(nil)
      @mock_tags.stub!(:find_by_name).with(@tag.name).and_return(@tag)
      @user.stub!(:tags).and_return(@mock_tags)
      User.stub!(:find_by_login).with('quentin').and_return(@user)
    end
  
    it_should_behave_like 'conditional GET of tag'
    it_should_behave_like 'tag access controls'
  
    it "should return 200 for show if last modified older than last classified" do
      @tag.stub!(:updated_on).and_return(Time.now.yesterday.yesterday)
      request.env['HTTP_IF_MODIFIED_SINCE'] = Time.now.yesterday.httpdate
    
      get "show", :tag_name => @tag.name, :user => 'quentin'
      response.should be_success
    end
    
    # it "atom_feed_contains_items_in_tag" do
    #   user = users(:quentin)
    #   tag = Tag(user, 'tag')
    #   tag.update_attribute :public, true
    # 
    #   user.taggings.create!(:feed_item => FeedItem.find(1), :tag => tag)
    #   user.taggings.create!(:feed_item => FeedItem.find(2), :tag => tag)
    # 
    #   get :show, :user_id => user.login, :id => tag, :format => "atom"
    # 
    #   response.should be_success
    #   # TODO: Move to view test
    #   # assert_select("entry", 2, response.body)
    # end

    it "atom_feed_with_missing_tag_returns_404" do
      @mock_tags.stub!(:find_by_id).with("missing").and_return(nil)
      get :show, :user => users(:quentin).login, :tag_name => "missing", :format => "atom"
      response.code.should == "404"
    end
  end
  
  describe "GET training" do
    before(:each) do
      @action = "training" # for 'conditional GET of tag'
      mock_user_for_controller
      @tag = mock_model(Tag, :updated_on => Time.now, :name => 'atag', :public? => true, :user_id => @user.id)    
      Tag.stub!(:find).with(@tag.id.to_s).and_return(@tag)
      @tag.stub!(:to_atom).and_return(Atom::Feed.new)
      @mock_tags = mock('tags')
      @mock_tags.stub!(:find_by_name).with(@tag.name).and_return(@tag)
      @user.stub!(:tags).and_return(@mock_tags)
      User.stub!(:find_by_login).with("quentin").and_return(@user)
    end
    
    it "should call to_atom with :training_only => true" do      
      @tag.should_receive(:to_atom).with(:training_only => true, :base_uri => 'http://test.host:80').and_return(Atom::Feed.new)
      get :training, :user => 'quentin', :tag_name => @tag.name
      response.should be_success
    end
    
    it "should set the content type to application/atom+xml" do
      @tag.should_receive(:to_atom).with(:training_only => true, :base_uri => 'http://test.host:80').and_return(Atom::Feed.new)
      get :training, :user => 'quentin', :tag_name => @tag.name, :format => 'atom'
      response.should be_success
      response.content_type.should == "application/atom+xml"
    end
    
    it "should set the Last-Modified header" do
      @tag.should_receive(:to_atom).with(:training_only => true, :base_uri => 'http://test.host:80').and_return(Atom::Feed.new)
      get :training, :user => 'quentin', :tag_name => @tag.name
      response.headers['Last-Modified'].should_not be_nil
    end
    
    it_should_behave_like 'conditional GET of tag'
    it_should_behave_like 'tag access controls'
  end
    
  describe "/classifier_taggings" do
    before(:each) do 
      mock_user_for_controller
      @tag = mock_model(Tag, :updated_on => Time.now, :name => 'atag', :public? => true, :user_id => @user.id)
      @mock_tags = mock('tags')
      @mock_tags.stub!(:find_by_name).with(@tag.name).and_return(@tag)
      @user.stub!(:tags).and_return(@mock_tags)
      User.stub!(:find_by_login).with("quentin").and_return(@user)
      @atom = mock('atom')
    end
    
    it "should return 400 without :atom" do
      put :classifier_taggings, :user => 'quentin', :tag_name => @tag.name
      response.code.should == "400"
    end
    
    it "should return 405 when not :put or :post" do
      get :classifier_taggings, :user => 'quentin', :tag_name => @tag.name, :format => 'atom'
      response.code.should == "405"
    end
    
    it "should call @tag.create_taggings_from_atom with POST and return 201" do      
      @tag.should_receive(:create_taggings_from_atom).with(@atom)
      post :classifier_taggings, :user => 'quentin', :tag_name => @tag.name, :atom => @atom, :format => 'atom'
      response.code.should == "204"
    end
    
    it "should call @tag.replace_taggings_from_atom with PUT and return 204" do
      @tag.should_receive(:replace_taggings_from_atom).with(@atom)
      put :classifier_taggings, :user => 'quentin', :tag_name => @tag.name, :atom => @atom, :format => 'atom'
      response.code.should =="204"
    end
    
    it "should not allow POST from other user" do
      @tag.stub!(:user_id).and_return(@user.id + 1)
      put :classifier_taggings, :user => 'quentin', :tag_name => @tag.name, :format => 'atom'
      response.code.should == "401"
    end
    
    it "should not allow POST when not logged in" do
      login_as(nil)
      put :classifier_taggings, :user => 'quentin', :tag_name => @tag.name, :format => 'atom'
      response.code.should == "401"
    end
    
    it "should not allow PUT from other user" do
      @tag.stub!(:user_id).and_return(@user.id + 1)
      post :classifier_taggings, :user => 'quentin', :tag_name => @tag.name, :format => 'atom'
      response.code.should == "401"
    end
    
    it "should not allow PUT when not logged in" do
      login_as(nil)
      post :classifier_taggings, :user => 'quentin', :tag_name => @tag.name, :format => 'atom'
      response.code.should == "401"
    end
    
    it "should allow POST when not logged in if the request is local" do
      login_as(nil)
      @controller.stub!(:local_request?).and_return(true)
      @tag.should_receive(:create_taggings_from_atom).with(@atom)
      post :classifier_taggings, :user => 'quentin', :tag_name => @tag.name, :atom => @atom, :format => 'atom'
      response.code.should == "204"
    end
    
    it "should allow PUT when not logged in if the request is local" do
      login_as(nil)
      @controller.stub!(:local_request?).and_return(true)
      @tag.should_receive(:replace_taggings_from_atom).with(@atom)
      put :classifier_taggings, :user => 'quentin', :tag_name => @tag.name, :atom => @atom, :format => 'atom'
      response.code.should == "204"
    end
  end
  
  describe "PUT /tags/id" do
    before(:each) do
      mock_user_for_controller
      @tag = mock_model(Tag, :updated_on => Time.now, :last_classified_at => Time.now, :name => 'Tag23', :public? => true, :user_id => @user.id)
      @mock_tags = mock('tags')
      @mock_tags.stub!(:find).with(@tag.id.to_s).and_return(@tag)
      @mock_tags.stub!(:find_by_name).with(@tag.name).and_return(@tag)
      @user.stub!(:tags).and_return(@mock_tags)
      User.stub!(:find_by_login).and_return(@user)
    end
    
    it "should update the tag's bias" do
      @tag.should_receive(:update_attribute).with(:bias, 1.2)
      put "update", :id => @tag.id, :tag => {:bias => 1.2}
      response.should be_success
    end
    
    it "should update the tag's bias via /:user/tags/:tag_name request" do
      @tag.should_receive(:update_attribute).with(:bias, 1.2)
      put "update", :user => 'quentin', :tag_name => @tag.name, :tag => {:bias => 1.2}
      response.should be_success
    end
    
    it "should not allow a logged in user to update someelse's tag" do
      @tag.stub!(:user_id).and_return(@user.id + 1)
      @tag.should_not_receive(:update_attribute).with(:bias, 1.2)
      put "update", :user => 'quentin', :tag_name => @tag.name, :tag => {:bias => 1.2}
      response.should_not be_success
    end
  end
  
  describe "DELETE" do
    before(:each) do
      mock_user_for_controller
      @tag = mock_model(Tag, valid_tag_attributes(:public? => false, :user_id => @user.id))
      @mock_tags = mock('tags')
      @mock_tags.stub!(:find).and_raise(ActiveRecord::RecordNotFound)
      @mock_tags.stub!(:find).with(@tag.id.to_s).and_return(@tag)
      @mock_tags.stub!(:find_by_name).with(@tag.name).and_return(@tag)
      @user.stub!(:tags).and_return(@mock_tags)
      User.stub!(:find_by_login).with(@user.login).and_return(@user)
    end
    
    it "/tags/id" do
      @tag.should_receive(:destroy)
      delete :destroy, :id => @tag.id
      response.should be_success
    end
    
    it "/user/tags/name" do
      @tag.should_receive(:destroy)
      delete :destroy, :user => @user.login, :tag_name => @tag.name
      response.code.should == "200"
    end
  
    it "destroy_by_unused_tag" do
      delete :destroy, :id => 999999999
      response.code.should ==  "404"
    end
    
    it "should prevent destruction of other user's tag" do
      tags = mock('other_user_tags')
      tag = mock_model(Tag, valid_tag_attributes(:public? => true))
      tag.should_not_receive(:destroy)
      tags.should_receive(:find_by_name).with(tag.name).and_return(tag)
      other_user = mock_model(User, valid_user_attributes)
      other_user.stub!(:tags).and_return(tags)
      User.stub!(:find_by_login).with(other_user.login).and_return(other_user)
      
      delete :destroy, :user => other_user.login, :tag_name => tag.name
      response.should_not be_success
    end
  end
  
  describe 'PUT subscribe' do
    it "subscribe_to_public_tag    " do
      other_user = users(:aaron)

      tag = Tag(other_user, 'hockey')
      tag.update_attribute :public, true
    
      TagSubscription.should_receive(:create!).with(:tag_id => tag.id, :user_id => users(:quentin).id)
    
      put :subscribe, :id => tag, :subscribe => "true"
    
      assert_response :success
    end
    
    # SG: This test ensures that the user's public tag is actually the one that is subscribed to.
    #     It also exposes the fact that sending only the name of the tag as the parameter is not
    #     sufficient, it also needs the name of the user since tags are only unique for a user.
    #     In fact it probably makes sense to use the public_tag route to call subscribe.
    it "subscribe_to_other_users_tag_with_same_name" do
      other_user = users(:aaron)
      tag = Tag(other_user, 'tag')
      tag.update_attribute :public, true
    
      TagSubscription.should_receive(:create!).with(:tag_id => tag.id, :user_id => users(:quentin).id)
    
      put :subscribe, :id => tag, :subscribe => "true"
    
      assert_response :success
    end

    # SG: This ensures that only public tags can be subscribed to.
    it "cant_subscribe_to_other_users_non_public_tags" do
      other_user = users(:aaron)
      tag = Tag(other_user, 'hockey')
      tag.update_attribute :public, false

      assert_no_difference("TagSubscription.count") do
        put :subscribe, :id => tag, :subscribe => "true"
      end
    
      assert_response :success 
    end
  
    # Test how unsubscribing as implemented on the "Public Tags" page
    it "unsubscribe_from_public_tag_via_subscribe_action" do
      other_user = users(:aaron)

      tag = Tag(other_user, 'hockey')
      tag.update_attribute :public, true
    
      TagSubscription.should_receive(:delete_all).with(:tag_id => tag.id, :user_id => users(:quentin).id)
    
      put :subscribe, :id => tag, :subscribe => "false"
    
      assert_response :success
    end

    # Test unsubscribing as implemented on the "My Tags" page
    it "unsubscribe_from_public_tag_via_unsubscribe_action" do
      referer("/tags")
      other_user = users(:aaron)

      tag = Tag(other_user, 'hockey')
      tag.update_attribute :public, true

      TagSubscription.should_receive(:delete_all).with(:tag_id => tag.id, :user_id => users(:quentin).id)
      Folder.should_receive(:remove_tag).with(users(:quentin), tag.id)

      put :unsubscribe, :id => tag

      assert_response :redirect
    end
  end
  
  describe 'sidebar' do
    # Test unsubscribing as implemented on the "My Tags" page
    it "sidebar - false" do
      tag = Tag(users(:quentin), 'hockey')

      Folder.should_receive(:remove_tag).with(users(:quentin), tag.id)

      put :sidebar, :id => tag, :sidebar => "false"

      assert_response :success
    end

    # Test unsubscribing as implemented on the "My Tags" page
    it "sidebar - true" do
      tag = Tag(users(:quentin), 'hockey')

      Folder.should_not_receive(:remove_tag)

      put :sidebar, :id => tag, :sidebar => "true"

      assert_response :success
    end
  end
  
  describe 'merge' do
    it "tag_merging" do
      old = Tag(users(:quentin), 'old')
      Tagging.create(:user => users(:quentin), :tag => old, :feed_item => FeedItem.find(1))
      Tagging.create(:user => users(:quentin), :tag => old, :feed_item => FeedItem.find(2))
      Tagging.create(:user => users(:quentin), :tag => Tag(users(:quentin), 'new'), :feed_item => FeedItem.find(3))
    
      put :merge, :id => old, :tag => {:name => 'new'}, :merge => "true"
      assert_redirected_to tags_path
      assert_equal("old merged with new", flash[:notice])
    end
  
    it "renaming_when_merge_will_happen" do
      old = Tag(users(:quentin), 'old')
      Tagging.create(:user => users(:quentin), :tag => old, :feed_item => FeedItem.find(1))
      Tagging.create(:user => users(:quentin), :tag => old, :feed_item => FeedItem.find(2))
      Tagging.create(:user => users(:quentin), :tag => Tag(users(:quentin), 'new'), :feed_item => FeedItem.find(3))
    
      put :update, :id => old, :tag => {:name => 'new'}
      response.should be_success
      response.should render_template("merge.js.rjs")
    end
  end
  
  describe 'rename' do    
    before(:each) do
      @tag = Tag(users(:quentin), 'tag')
    end
    
    it "rename the tag" do
      put :update, :id => @tag, :tag => {:name => 'new'}
      response.should be_success
      assert users(:quentin).tags.find_by_name('new')
    end    
  end
  
  describe 'PUT update_state' do
    before(:each) do
      @tag = mock_model(Tag, :id => "1")
      Tag.should_receive(:find).with(@tag.id).and_return(@tag)
    end
    
    after(:each) do
      response.should be_success
      response.should render_template("tags/update_state")
    end
    
    def do_put(state)
      put :update_state, :id => @tag.id, :state => state
    end
    
    it "updates the tag state to globally exclude" do
      @tag_exclusions = stub("tag_exclusions")
      current_user.should_receive(:tag_exclusions).and_return(@tag_exclusions)      
      @tag_exclusions.should_receive(:create!).with(:tag_id => @tag.id)
            
      TagSubscription.should_receive(:delete_all).with(:tag_id => @tag.id, :user_id => current_user.id)
      Folder.should_receive(:remove_tag).with(current_user, @tag.id)
      
      do_put "globally_exclude"
    end
    
    it "updates the tag state to subscribed" do
      TagSubscription.should_receive(:create!).with(:tag_id => @tag.id, :user_id => current_user.id)
      TagExclusion.should_receive(:delete_all).with(:tag_id => @tag.id, :user_id => current_user.id)
      
      do_put "subscribe"
    end
    
    it "updates the tag state to neither" do
      TagSubscription.should_receive(:delete_all).with(:tag_id => @tag.id, :user_id => current_user.id)
      Folder.should_receive(:remove_tag).with(current_user, @tag.id)
      TagExclusion.should_receive(:delete_all).with(:tag_id => @tag.id, :user_id => current_user.id)
      
      do_put "neither"
    end
  end
end