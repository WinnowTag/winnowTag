# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

shared_examples_for 'conditional GET of tag' do
  it "should return not modified for show if if_modified after as updated on and last classified" do
    time = Time.now.yesterday
    @tag.stub!(:updated_on).and_return(time)
    @tag.stub!(:last_classified_at).and_return(time)    
    @tag.should_receive(:to_atom).never
    request.env['HTTP_IF_MODIFIED_SINCE'] = Time.now.httpdate
  
    get @action, :tag_name => @tag.name, :user => @user.login
    response.code.should == '304'
  end

  it "should return 200 for show if if_modified_since older than updated on" do      
    @tag.stub!(:last_classified_at).and_return(Time.now.yesterday.yesterday)
    request.env['HTTP_IF_MODIFIED_SINCE'] = Time.now.yesterday.httpdate
  
    get @action, :tag_name => @tag.name, :user => @user.login
    response.should be_success
  end
end

shared_examples_for 'tag access controls' do
  it "anyone can access feeds if the tag is public" do
    @tag.stub!(:public?).and_return(true)
    login_as(nil)
    get @action, :user => @user.login, :tag_name => @tag.name, :format => "atom"
    response.should be_success
  end
  
  it "should prevent anyone accessing private tags" do
    @tag.stub!(:public?).and_return(false)
    login_as(nil)
    get @action, :user => @user.login, :tag_name => @tag.name, :format => "atom"
    response.code.should == "401"
  end
  
  it "should allow the owner to access private tags" do
    @tag.stub!(:public?).and_return(false)
    login_as @user
    get @action, :user => @user.login, :tag_name => @tag.name, :format => "atom"
    response.code.should == "200"
  end
  
  it "should allow hmac authenticated requests to access private tags regardless of login" do
    @tag.stub!(:public?).and_return(false)
    login_as(nil)
    @controller.stub!(:hmac_authenticated?).and_return(true)
    get @action, :user => @user.login, :tag_name => @tag.name, :format => "atom"
    response.code.should == "200"
  end
end

describe TagsController do
  before(:each) do
    @user = Generate.user!
    @feed_item = Generate.feed_item!
    
    login_as @user
  end
  
  describe "create" do
    before(:each) do
      @tag = Generate.tag!(:user => @user)
      @tagging = Tagging.create(:user => @user, :tag => @tag, :feed_item => @feed_item)
    end

    it "copies named tag" do
      @user.taggings.create(:tag => @tag, :feed_item => @feed_item)
      assert_difference("@user.tags.count") do
        post :create, :copy => @tag.id, :name => "tag - copy"
        assert_response :success
        assert_equal("<span class='name'>#{@tag.name}</span> successfully copied to <span class='name'>tag - copy</span>", flash[:notice])
      end
      assert @user.tags.find(:first, :conditions => ['tags.name = ?', 'tag - copy'])
      assert_equal(2, @user.taggings.size)
    end
  
    it "prompts the user to overwrite when copying to an existing tag" do
      tag2 = Generate.tag!(:user => @user)
    
      post :create, :copy => @tag.id, :name => tag2.name
      assert_response :success
    
      assert_match /confirm/, response.body
    end
  
    it "overwrites an existing tag when overwrite is set to true" do
      tag2 = Generate.tag!(:user => @user)
    
      feed_item2 = Generate.feed_item!
    
      @user.taggings.create(:tag => @tag, :feed_item => @feed_item)
      @user.taggings.create(:tag => tag2, :feed_item => feed_item2)

      assert_equal [@feed_item], @tag.taggings.map(&:feed_item)
      assert_equal [feed_item2], tag2.taggings.map(&:feed_item)

      assert_difference("@user.tags.count", 0) do
        post :create, :copy => @tag.id, :name => tag2.name, :overwrite => "true"
        assert_response :success
        assert_equal("<span class='name'>#{@tag.name}</span> successfully copied to <span class='name'>#{tag2.name}</span>", flash[:notice])
      end

      assert_equal [@feed_item], tag2.taggings(:reload).map(&:feed_item)
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
      response.should be_success
    end
    
    it "should reject the unauthenticated" do
      login_as(nil)
      get :index, :format => 'atom'
      response.code.should == "401"
    end
    
    it "should handle hmac authentication" do
      login_as(nil)
      @controller.stub!(:hmac_authenticated?).and_return(true)
      get :index, :format => 'atom'
      response.should be_success
    end
    
    it "should handle basic authentication" do
      login_as(nil)
      @controller.stub!(:login_required).and_return(true)
      get :index
      response.should be_success
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
      get :index, :format => "atom"
      response.should be_success
    end
        
    it "should have application/atom+xml as the content type" do
      get :index, :format => "atom"
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
    
    it "should respond with a 304 if there are no new tags" do
      Tag.should_receive(:all_ids).and_return([1,2,3,4])
      Tag.should_not_receive(:to_atom).with(:base_uri => "http://test.host:80")
      request.env['HTTP_IF_NONE_MATCH'] = %("#{Digest::MD5.hexdigest(ActiveSupport::Cache.expand_cache_key([1,2,3,4]))}")
      get :index, :format => 'atom'
      response.code.should == "304"
    end
    
    it "should responde with a 200 if there are new tags since HTTP_IF_MODIFIED_SINCE" do
      request.env['HTTP_IF_NONE_MATCH'] = %("#{Digest::MD5.hexdigest(ActiveSupport::Cache.expand_cache_key([1]))}")
      get :index, :format => 'atom'
      response.code.should == "200"
    end
    
    it "should not require a login for hmac_authenticated requests" do
      login_as(nil)
      @controller.stub!(:hmac_authenticated?).and_return(true)
      get :index, :format => 'atom'
      response.should be_success
    end    
  end
  
  describe "show" do
    before(:each) do
      @action = "show" # for 'conditional GET of tag'
      @tag = mock_model(Tag, :updated_on => Time.now, :last_classified_at => Time.now, :name => 'Tag23', :public? => true, :user_id => @user.id)
      @tag.stub!(:to_atom).and_return(Atom::Feed.new)
      @mock_tags = mock('tags')
      @mock_tags.stub!(:find_by_name).and_return(nil)
      @mock_tags.stub!(:find_by_name).with(@tag.name).and_return(@tag)
      @user.stub!(:tags).and_return(@mock_tags)
      User.stub!(:find_by_login).with(@user.login).and_return(@user)
      
      TagUsage.stub!(:create!)
    end
  
    it_should_behave_like 'conditional GET of tag'
    it_should_behave_like 'tag access controls'
  
    it "should return 200 for show if last modified older than last classified" do
      @tag.stub!(:updated_on).and_return(Time.now.yesterday.yesterday)
      request.env['HTTP_IF_MODIFIED_SINCE'] = Time.now.yesterday.httpdate
    
      get :show, :tag_name => @tag.name, :user => @user.login
      response.should be_success
    end
    
    it "atom_feed_contains_items_in_tag" do
      tag = Generate.tag! :user => @user, :public => true
      feed_item1 = Generate.feed_item!
      feed_item2 = Generate.feed_item!
    
      @user.taggings.create!(:feed_item => feed_item1, :tag => tag)
      @user.taggings.create!(:feed_item => feed_item2, :tag => tag)

      @mock_tags.stub!(:find).with(tag.id.to_s).and_return(tag)
    
      get :show, :user_id => @user.login, :id => tag.id, :format => "atom"
    
      response.should be_success
    end

    it "atom_feed_with_missing_tag_returns_404" do
      @mock_tags.stub!(:find_by_id).with("missing").and_return(nil)
      get :show, :user => @user.login, :tag_name => "missing", :format => "atom"
      response.code.should == "404"
    end
  end

  describe "GET training" do
    before(:each) do
      @action = "training" # for 'conditional GET of tag'
      @tag = mock_model(Tag, :updated_on => Time.now, :name => 'atag', :public? => true, :user_id => @user.id)    
      Tag.stub!(:find).with(@tag.id.to_s).and_return(@tag)
      @tag.stub!(:to_atom).and_return(Atom::Feed.new)
      @mock_tags = mock('tags')
      @mock_tags.stub!(:find_by_name).with(@tag.name).and_return(@tag)
      @user.stub!(:tags).and_return(@mock_tags)
      User.stub!(:find_by_login).with(@user.login).and_return(@user)
    end
    
    it "should call to_atom with :training_only => true" do      
      @tag.should_receive(:to_atom).with(:training_only => true, :base_uri => 'http://test.host:80').and_return(Atom::Feed.new)
      get :training, :user => @user.login, :tag_name => @tag.name
      response.should be_success
    end
    
    it "should set the content type to application/atom+xml" do
      @tag.should_receive(:to_atom).with(:training_only => true, :base_uri => 'http://test.host:80').and_return(Atom::Feed.new)
      get :training, :user => @user.login, :tag_name => @tag.name, :format => 'atom'
      response.should be_success
      response.content_type.should == "application/atom+xml"
    end
    
    it "should set the Last-Modified header" do
      @tag.should_receive(:to_atom).with(:training_only => true, :base_uri => 'http://test.host:80').and_return(Atom::Feed.new)
      get :training, :user => @user.login, :tag_name => @tag.name
      response.headers['Last-Modified'].should_not be_nil
    end
    
    it_should_behave_like 'conditional GET of tag'
    it_should_behave_like 'tag access controls'
  end
    
  describe "/classifier_taggings" do
    before(:each) do
      @tag = mock_model(Tag, :updated_on => Time.now, :name => 'atag', :public? => true, :user_id => @user.id)
      @mock_tags = mock('tags')
      @mock_tags.stub!(:find_by_name).with(@tag.name).and_return(@tag)
      @user.stub!(:tags).and_return(@mock_tags)
      User.stub!(:find_by_login).with(@user.login).and_return(@user)
      @atom = mock('atom')
    end
    
    it "should return 400 without :atom" do
      @controller.stub!(:hmac_authenticated?).and_return(true)
      put :classifier_taggings, :user => @user.login, :tag_name => @tag.name
      response.code.should == "400"
    end
    
    it "should call @tag.create_taggings_from_atom with POST and return 201" do
      @controller.stub!(:hmac_authenticated?).and_return(true)
      @tag.should_receive(:create_taggings_from_atom).with(@atom)
      post :classifier_taggings, :user => @user.login, :tag_name => @tag.name, :atom => @atom, :format => 'atom'
      response.code.should == "204"
    end
    
    it "should call @tag.replace_taggings_from_atom with PUT and return 204" do
      @controller.stub!(:hmac_authenticated?).and_return(true)
      @tag.should_receive(:replace_taggings_from_atom).with(@atom)
      put :classifier_taggings, :user => @user.login, :tag_name => @tag.name, :atom => @atom, :format => 'atom'
      response.code.should =="204"
    end
    
    it "should not allow POST from other user" do
      @tag.stub!(:user_id).and_return(@user.id + 1)
      put :classifier_taggings, :user => @user.login, :tag_name => @tag.name, :format => 'atom', :atom => @atom
      response.code.should == "401"
    end
    
    it "should not allow POST when not logged in" do
      login_as(nil)
      post :classifier_taggings, :user => @user.login, :tag_name => @tag.name, :format => 'atom'
      response.code.should == "401"
    end
    
    it "should not allow PUT from other user" do
      @tag.stub!(:user_id).and_return(@user.id + 1)
      post :classifier_taggings, :user => @user.login, :tag_name => @tag.name, :format => 'atom'
      response.code.should == "401"
    end
    
    it "should not allow PUT when not logged in" do
      login_as(nil)
      put :classifier_taggings, :user => @user.login, :tag_name => @tag.name, :format => 'atom'
      response.code.should == "401"
    end    
  end
  
  describe "PUT /tags/id" do
    before(:each) do
      @tag = Generate.tag!(:user => @user, :public => true, :bias => 1)
      login_as @user
    end
    
    it "should update the tag's bias" do
      put "update", :id => @tag.id, :tag => { :bias => 1.2 }
      response.should be_success
      @tag.reload.bias.should == 1.2
    end
    
    it "should update the tag's bias via /:user/tags/:tag_name request" do
      put "update", :user => @user.login, :tag_name => @tag.name, :tag => { :bias => 1.2 }
      response.should be_success
      @tag.reload.bias.should == 1.2
    end
    
    it "should not allow a logged in user to update someelse's tag" do
      tag = Generate.tag! :bias => 1
      put "update", :user => @user.login, :tag_name => tag.name, :tag => { :bias => 1.2 }
      response.should_not be_success
      tag.reload.bias.should_not == 1.2
    end
  end
  
  describe "DELETE" do
    before(:each) do
      @tag = Generate.tag!(:user => @user)
      login_as @user
    end
    
    it "/tags/id" do
      delete :destroy, :id => @tag.id
      response.should be_success
      lambda {
        @tag.reload
      }.should raise_error(ActiveRecord::RecordNotFound)
    end
    
    it "/user/tags/name" do
      delete :destroy, :user => @user.login, :tag_name => @tag.name
      response.should be_success
      lambda {
        @tag.reload
      }.should raise_error(ActiveRecord::RecordNotFound)
    end
  
    it "destroy_by_unused_tag" do
      delete :destroy, :id => 999999999
      response.code.should ==  "404"
    end
    
    it "should prevent destruction of other user's tag" do
      user = Generate.user!
      tag = Generate.tag!(:user => user)
      delete :destroy, :user => user.login, :tag_name => tag.name
      response.should_not be_success
      lambda { tag.reload }.should_not raise_error(ActiveRecord::RecordNotFound)
    end

    it "should archive the tag if there are subscriptions" do
      public_tag = Generate.tag!(:user => @user, :name => "public_tag", :public => true)
      user2 = Generate.user!
      archive = Generate.user!(:login => "archive")
      TagSubscription.create! :tag_id => public_tag.id, :user_id => user2.id
      TagExclusion.create! :tag_id => public_tag.id, :user_id => user2.id
      delete :destroy, :id => public_tag.id
      response.should be_success
      lambda {
        public_tag.reload
      }.should raise_error(ActiveRecord::RecordNotFound)
      assert archive.tags.find_by_name("public_tag")
      assert archive.tags.find_by_name("public_tag").tag_subscriptions.size == 1
      assert archive.tags.find_by_name("public_tag").tag_exclusions.size == 1
    end
  end
  
  describe 'PUT subscribe' do
    it "subscribe_to_public_tag" do
      user2 = Generate.user!
      tag = Generate.tag!(:user => user2, :public => true)
    
      TagSubscription.should_receive(:create!).with(:tag_id => tag.id, :user_id => @user.id)
      put :subscribe, :id => tag.id, :subscribe => "true", :format => "js"
      assert_response :success
    end
    
    # SG: This test ensures that the user's public tag is actually the one that is subscribed to.
    #     It also exposes the fact that sending only the name of the tag as the parameter is not
    #     sufficient, it also needs the name of the user since tags are only unique for a user.
    #     In fact it probably makes sense to use the public_tag route to call subscribe.
    it "subscribe_to_other_users_tag_with_same_name" do
      user2 = Generate.user!
      tag = Generate.tag!(:user => user2, :public => true)
    
      TagSubscription.should_receive(:create!).with(:tag_id => tag.id, :user_id => @user.id)
      put :subscribe, :id => tag.id, :subscribe => "true", :format => "js"
      assert_response :success
    end

    # Test unsubscribing as implemented on the "Public Tags" page
    it "unsubscribe_from_public_tag_via_subscribe_action" do
      user2 = Generate.user!
      tag = Generate.tag!(:user => user2, :public => true)

    
      TagSubscription.should_receive(:delete_all).with(:tag_id => tag.id, :user_id => @user.id)
      put :unsubscribe, :id => tag, :format => "js"
      assert_response :success
    end

    # Test unsubscribing as implemented on the "My Tags" page
    it "unsubscribe_from_public_tag_via_unsubscribe_action" do
      user2 = Generate.user!
      tag = Generate.tag!(:user => user2, :public => true)

      referer("/tags")

      TagSubscription.should_receive(:delete_all).with(:tag_id => tag.id, :user_id => @user.id)

      put :unsubscribe, :id => tag
      assert_response :redirect
    end
    
    it "subscribing multiple times to the same public tag creates only one subscription" do
      user2 = Generate.user!
      tag = Generate.tag!(:user => user2, :public => true)
      
      lambda {
        put :subscribe, :id => tag, :subscribe => "true", :format => "js"
        put :subscribe, :id => tag, :subscribe => "true", :format => "js"
      }.should change(TagSubscription, :count).by(1)
      
      assert_response :success
    end
  end
  
  describe 'merge' do
    it "tag_merging" do
      tag1 = Generate.tag!(:user => @user)
      tag2 = Generate.tag!(:user => @user)
      feed_item1 = Generate.feed_item!
      feed_item2 = Generate.feed_item!
      feed_item3 = Generate.feed_item!
      
      @user.taggings.create!(:tag => tag1, :feed_item => feed_item1)
      @user.taggings.create!(:tag => tag1, :feed_item => feed_item2)
      @user.taggings.create!(:tag => tag2, :feed_item => feed_item3)
    
      put :merge, :id => tag1, :tag => { :name => tag2.name }, :merge => "true"
      assert_redirected_to tags_path
      assert_equal("Examples of <span class='name'>#{tag1.name}</span> successfully merged into <span class='name'>#{tag2.name}</span>", flash[:notice])
    end
  
    it "renaming_when_merge_will_happen" do
      tag1 = Generate.tag!(:user => @user)
      tag2 = Generate.tag!(:user => @user)
      feed_item1 = Generate.feed_item!
      feed_item2 = Generate.feed_item!
      feed_item3 = Generate.feed_item!
      
      @user.taggings.create!(:tag => tag1, :feed_item => feed_item1)
      @user.taggings.create!(:tag => tag1, :feed_item => feed_item2)
      @user.taggings.create!(:tag => tag2, :feed_item => feed_item3)

      put :update, :id => tag1, :tag => { :name => tag2.name }
      response.should be_success
      response.should render_template("merge.js.rjs")
    end
  end
  
  describe 'rename' do    
    before(:each) do
      @tag = Generate.tag!(:user => @user)
    end
    
    it "rename the tag" do
      put :update, :id => @tag, :tag => { :name => 'new' }
      response.should be_success
      assert @user.tags.find_by_name('new')
    end    
  end
  
  describe "publicize" do
    before(:each) do
      @tag = mock_model(Tag, :user_id => @user.id)
      Tag.should_receive(:find).with("111").and_return(@tag)
    end
    
    it "should call the publicize setter on the tag" do
      @tag.should_receive(:update_attribute).with(:public, "true")
      put :publicize, :id => "111", :public => "true"
      response.should be_success
    end
  end
end

describe TagsController, "GET show when not logged in" do
  it "logs a tag usage with the client's ip address" do
    user = Generate.user!
    tag = Generate.tag!(:user => user, :public => true)

    TagUsage.should_receive(:create!).with(:tag_id => tag.id, :ip_address => "3.4.5.6")
    
    request.env['REMOTE_ADDR'] = '3.4.5.6'
    get :show, :user => user.login, :tag_name => tag.name, :format => "atom"
  end
end


describe TagsController do
  describe "#comments" do
    def get_comments
      xhr :get, :comments, :id => @tag.id
    end
    
    before(:each) do
      @current_user = Generate.user!
      @tag = Generate.tag! :user => @current_user
      @tag.comments = [
        Generate.comment!(:tag => @tag),
        Generate.comment!(:tag => @tag)
      ]
    
      Tag.stub!(:find).and_return(@tag)
      
      login_as @current_user
    end
    
    it "finds the tag" do
      Tag.should_receive(:find).with(@tag.id.to_s).and_return(@tag)
      get_comments
    end
    
    it "marks the tag's comments as read" do
      @tag.comments.each do |comment|
        comment.should_receive(:read_by!).with(@current_user)
      end
      get_comments
    end
    
    it "renders the comments template" do
      get_comments
      response.should render_template("comments")
    end
  end
end