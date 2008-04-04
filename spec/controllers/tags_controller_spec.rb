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
    request.env['HTTP_IF_MODIFIED_SINCE'] = Time.now.httpdate
  
    get @action, :id => @tag.id, :user_id => 'quentin'
    response.code.should == '304'
  end

  it "should return 200 for show if if_modified_since older than updated on" do      
    @tag.stub!(:last_classified_at).and_return(Time.now.yesterday.yesterday)
    request.env['HTTP_IF_MODIFIED_SINCE'] = Time.now.yesterday.httpdate
  
    get @action, :id => @tag.id, :user_id => 'quentin'
    response.should be_success
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
        assert_equal("'tag' successfully copied to 'tag - copy'", flash[:notice])
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
        assert_equal("'tag' successfully copied to 'tag2'", flash[:notice])
      end

      assert_equal [feed_item_1], tag2.taggings(:reload).map(&:feed_item)
    end
    
    it "can create a new tag" do
      assert_difference "Tag.count" do
        post :create, :name => "new tag"
      end
    end
  end
  
  describe "index with Accept: application/atomsvc+xml" do
    before(:each) do
      Tag.stub!(:maximum).with(:created_on).and_return(Time.now)
      Tag.stub!(:to_atomsvc).with(:base_uri => "http://test.host:80").and_return(Atom::Pub::Service.new)
    end
    
    it "should call Tag.to_atomsvc" do
      Tag.should_receive(:to_atomsvc).with(:base_uri => "http://test.host:80").and_return(Atom::Pub::Service.new)
      get :index, :format => 'atomsvc'      
    end
    
    it "should be successful" do
      accept('application/atomsvc+xml')
      get :index
      response.should be_success
    end
        
    it "should have application/atomsvc+xml as the content type" do
      accept('application/atomsvc+xml')
      get :index
      response.content_type.should == "application/atomsvc+xml"
    end
    
    it "should have application/atomsvc+xml as the content type when :format is atomsvc" do
      get :index, :format => 'atomsvc'
      response.content_type.should == "application/atomsvc+xml"
    end
    
    it "should have the atom content" do
      get :index, :format => 'atomsvc'
      response.body.should match(%r{<service})
    end
    
    it "should respond with a 304 if there are no new tags since HTTP_IF_MODIFIED_SINCE" do
      Tag.should_receive(:maximum).with(:created_on).and_return(Time.now.yesterday)
      Tag.should_not_receive(:to_atom_svc).with(:base_uri => "http://test.host:80")
      request.env['HTTP_IF_MODIFIED_SINCE'] = Time.now.httpdate
      get :index, :format => 'atomsvc'
      response.code.should == "304"
    end
    
    it "should responde with a 200 if there are new tags since HTTP_IF_MODIFIED_SINCE" do
      request.env['HTTP_IF_MODIFIED_SINCE'] = 30.days.ago.httpdate
      get :index, :format => 'atomsvc'
      response.code.should == "200"
    end
  end
  
  describe "show" do
    before(:each) do
      @action = "show" # for 'conditional GET of tag'
      mock_user_for_controller
      @tag = mock_model(Tag, :updated_on => Time.now, :last_classified_at => Time.now)
      @tags.stub!(:find_by_id).and_return(@tag)
      @mock_tags = mock('tags')
      @mock_tags.stub!(:find_by_id).and_return(@tag)
      @user.stub!(:tags).and_return(@mock_tags)
      User.stub!(:find_by_login).and_return(@user)
    end
  
    it "should update the tag's bias" do
      @tag.should_receive(:update_attribute).with(:bias, 1.2)
      put "update", :id => 1, :tag => {:bias => 1.2}
      response.should be_success
    end
  
    it_should_behave_like 'conditional GET of tag'
  
    it "should return 200 for show if last modified older than last classified" do
      @tag.stub!(:updated_on).and_return(Time.now.yesterday.yesterday)
      request.env['HTTP_IF_MODIFIED_SINCE'] = Time.now.yesterday.httpdate
    
      get "show", :id => 1, :user_id => 'quentin'
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
      get :show, :user_id => users(:quentin).login, :id => "missing", :format => "atom"
      response.code.should == "404"
    end

    it "anyone_can_access_feeds" do
      login_as(nil)
      get :show, :user_id => 'quentin', :id => 1, :format => "atom"
      response.should be_success
    end
  end
  
  describe "GET training" do
    before(:each) do
      @action = "training" # for 'conditional GET of tag'
      @tag = mock_model(Tag, :updated_on => Time.now)    
      Tag.stub!(:find).with(@tag.id.to_s).and_return(@tag)
      @tag.should_receive(:to_atom).with(:training_only => true, :base_uri => 'http://test.host:80').and_return(Atom::Feed.new)
    end
    
    it "should call to_atom with :training_only => true" do      
      get :training, :id => @tag.id
      response.should be_success
    end
    
    it "should set the content type to application/atom+xml" do
      get :training, :id => @tag.id, :format => 'atom'
      response.should be_success
      response.content_type.should == "application/atom+xml"
    end
    
    it "should set the Last-Modified header" do
      get :training, :id => @tag.id
      response.headers['Last-Modified'].should_not be_nil
    end
    
    it_should_behave_like 'conditional GET of tag'
  end
    
  describe "/classifier_taggings" do
    before(:each) do 
      @tag = mock_model(Tag)
      Tag.stub!(:find).with(@tag.id.to_s).and_return(@tag)
    end
    
    it "should return 400 without :atom" do
      put :classifier_taggings, :id => @tag.id
      response.code.should == "400"
    end
    
    it "should return 405 when not :put or :post" do
      get :classifier_taggings, :id => @tag.id
      response.code.should == "405"
    end
    
    it "should call @tag.create_taggings_from_atom with POST and return 201" do
      atom = mock('atom')
      @tag.should_receive(:create_taggings_from_atom).with(atom)
      post :classifier_taggings, :id => @tag.id, :atom => atom
      response.code.should == "204"
    end
    
    it "should call @tag.replace_taggings_from_atom with PUT and return 204" do
      atom = mock('atom')
      @tag.should_receive(:replace_taggings_from_atom).with(atom)
      put :classifier_taggings, :id => @tag.id, :atom => atom
      response.code.should =="204"
    end
  end
  
  describe "from test/unit" do
    before(:each) do
      @tag = Tag(users(:quentin), 'tag')
      @tagging = Tagging.create(:user => users(:quentin), :tag => @tag, :feed_item => FeedItem.find(1))
    end

    # it "routing" do
    #   assert_routing('/tags/atag', :controller => 'tags', :action => 'show', :id => 'atag')
    #   assert_routing('/tags/my+tag', :controller => 'tags', :action => 'show', :id => 'my tag')
    #   assert_routing('/tags/edit/my+tag.', :controller => 'tags', :action => 'edit', :id => 'my tag.')
    # end
  
    it "index" do
      get :index
      assert assigns(:tags)
      assert_equal(@tag, assigns(:tags).first)
      assert assigns(:subscribed_tags)
      # TODO: Move this to a view test
      # assert_select "tr##{dom_id(@tag)}", 1
      # assert_select "tr##{dom_id(@tag)} td:nth-child(1)", /tag.*/
      # assert_select "tr##{dom_id(@tag)} td:nth-child(5)", "1 / 0"
      # assert_select "tr##{dom_id(@tag)} td:nth-child(6)", "0"
    end
  
    # TODO - Tags with periods on the end break routing until Rails 1.2.4?
    it "index_with_funny_name_tag" do
      Tagging.create(:user => users(:quentin), :tag => Tag(users(:quentin), 'tag.'), :feed_item => FeedItem.find(1))
      get :index
      assert_response :success
    end
  
    it "edit_with_funny_name_tag" do
      tag_dot = Tag(users(:quentin), 'tag.')
      Tagging.create(:user => users(:quentin), :tag => tag_dot, :feed_item => FeedItem.find(1))
      get :edit, :id => tag_dot
      assert_response :success
    end
  
    it "edit" do
      get :edit, :id => @tag
      assert assigns(:tag)
      assert_template 'edit'
    end
  
    it "edit_with_missing_tag" do
      get :edit, :id => 'missing'
      assert_response 404
    end
  
    it "edit_with_js" do
      get :edit, :id => @tag, :format => :js
      assert assigns(:tag)
      # TODO: Move to view test
      # assert_select "html", false
      # assert_select "form[action='#{tag_path(@tag)}']", 1, @response.body
    end
  
    it "tag_renaming_with_same_tag" do
      put :update, :id => @tag, :tag => {:name => 'tag' }
      assert_redirected_to tags_path
      assert_equal([@tag], users(:quentin).tags)
    end
  
    it "tag_renaming" do
      put :update, :id => @tag, :tag => {:name => 'new'}
      assert_redirected_to tags_path
      assert users(:quentin).tags.find_by_name('new')
    end
  
    it "tag_merging" do
      old = Tag(users(:quentin), 'old')
      Tagging.create(:user => users(:quentin), :tag => old, :feed_item => FeedItem.find(1))
      Tagging.create(:user => users(:quentin), :tag => old, :feed_item => FeedItem.find(2))
      Tagging.create(:user => users(:quentin), :tag => Tag(users(:quentin), 'new'), :feed_item => FeedItem.find(3))
    
      put :update, :id => old, :tag => {:name => 'new'}, :merge => "true"
      assert_redirected_to tags_path
      assert_equal("'old' merged with 'new'", flash[:notice])
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
  
    it "destroy_by_tag" do
      login_as(:quentin)
      user = users(:quentin)
      to_destroy = Tag(user, 'to_destroy')
      to_keep = Tag(user, 'to_keep')
      user.taggings.create(:tag => to_destroy, :feed_item => FeedItem.find(1))
      user.taggings.create(:tag => to_destroy, :feed_item => FeedItem.find(2))
      user.taggings.create(:tag => to_destroy, :feed_item => FeedItem.find(3))
      keep = user.taggings.create(:tag => to_keep, :feed_item => FeedItem.find(1))
    
      assert_equal [@tag, to_destroy, to_keep], user.tags
    
      delete :destroy, :id => to_destroy
      assert_response :success
      assert_equal [@tag, to_keep], users(:quentin).tags(true)
      assert_equal([@tagging, keep], user.taggings(true))
    end
  
    it "destroy_by_tag_destroys_classifier_taggings" do
      login_as(:quentin)
      user = users(:quentin)
      to_destroy = Tag(user, 'to_destroy')
      to_keep = Tag(user, 'to_keep')
    
      user.taggings.create(:tag => to_destroy, :feed_item => FeedItem.find(1))
      user.taggings.create(:tag => to_destroy, :feed_item => FeedItem.find(2), :classifier_tagging => true)
      user.taggings.create(:tag => to_destroy, :feed_item => FeedItem.find(3), :classifier_tagging => true)
      keep = user.taggings.create(:tag => to_keep, :feed_item => FeedItem.find(1), :classifier_tagging => true)
    
      delete :destroy, :id => to_destroy
      assert_response :success
      assert_equal [@tagging, keep], user.taggings(true)
    end
  
    it "destroy_by_unused_tag" do
      login_as(:quentin)
      delete :destroy, :id => 999999999
      assert_response 404
    end

    it "subscribe_to_public_tag    " do
      other_user = users(:aaron)

      tag = Tag(other_user, 'hockey')
      tag.update_attribute :public, true
    
      TagSubscription.should_receive(:create!).with(:tag_id => tag.id, :user_id => users(:quentin).id)
    
      put :subscribe, :id => tag, :subscribe => "true"
    
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

      put :unsubscribe, :id => tag

      assert_response :redirect
    end
  
    # SG: This test ensures that the user's public tag is actually the one that is subscribed to.
    #     It also exposes the fact that sending only the name of the tag as the parameter is not
    #     sufficient, it also needs the name of the user since tags are only unique for a user.
    #     In fact it probably makes sense to use the public_tag route to call subscribe.
    #
    #     This test is currently failing, Craig should probably be the one to fix it.
    #
    it "subscribe_to_other_users_tag_with_same_name" do
      other_user = users(:aaron)
      tag = Tag(other_user, 'tag')
      tag.update_attribute :public, true
    
      TagSubscription.should_receive(:create!).with(:tag_id => tag.id, :user_id => users(:quentin).id)
    
      put :subscribe, :id => tag, :subscribe => "true"
    
      assert_response :success
    end

    # SG: This ensures that only public tags can be subscribed to.
    # 
    it "cant_subscribe_to_other_users_non_public_tags" do
      other_user = users(:aaron)
      tag = Tag(other_user, 'hockey')
      tag.update_attribute :public, false

      assert_no_difference("TagSubscription.count") do
        put :subscribe, :id => tag, :subscribe => "true"
      end
    
      assert_response :success 
    end
  end
end