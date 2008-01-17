require File.dirname(__FILE__) + '/../test_helper'
require 'tags_controller'

# Re-raise errors caught by the controller.
class TagsController; def rescue_action(e) raise e end; end

class TagsControllerTest < Test::Unit::TestCase
  fixtures :users, :tags, :feed_items
  def setup
    @controller = TagsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    login_as(:quentin)
    @tag = Tag(users(:quentin), 'tag')
    @tagging = Tagging.create(:user => users(:quentin), :tag => @tag, :feed_item => FeedItem.find(1))
  end

  # def test_routing
  #   assert_routing('/tags/atag', :controller => 'tags', :action => 'show', :id => 'atag')
  #   assert_routing('/tags/my+tag', :controller => 'tags', :action => 'show', :id => 'my tag')
  #   assert_routing('/tags/edit/my+tag.', :controller => 'tags', :action => 'edit', :id => 'my tag.')
  # end
  
  def test_create_should_copy_named_tag
    users(:quentin).taggings.create(:tag => @tag, :feed_item => FeedItem.find(1))
    assert_difference(users(:quentin).tags, :count) do
      post :create, :copy => @tag, :name => "tag - copy"
      assert_response :success
      assert_equal("'tag' successfully copied to 'tag - copy'", flash[:notice])
    end
    assert users(:quentin).tags.find(:first, :conditions => ['tags.name = ?', 'tag - copy'])
    assert_equal(2, users(:quentin).taggings.size)
  end
  
  def test_copying_tag_to_an_already_existing_name_prompts_the_user_to_overwrite
    tag2 = Tag(users(:quentin), 'tag2')
    
    post :create, :copy => @tag, :name => "tag2"
    assert_response :success
    
    assert_match /confirm/, @response.body
  end
  
  def test_copying_tag_to_an_already_existing_name_with_overwrite_flag
    tag2 = Tag(users(:quentin), 'tag2')
    
    feed_item_1 = FeedItem.find(1)
    feed_item_2 = FeedItem.find(2)
    
    users(:quentin).taggings.create(:tag => @tag, :feed_item => feed_item_1)
    users(:quentin).taggings.create(:tag => tag2, :feed_item => feed_item_2)

    assert_equal [feed_item_1], @tag.taggings.map(&:feed_item)
    assert_equal [feed_item_2], tag2.taggings.map(&:feed_item)

    assert_difference(users(:quentin).tags, :count, 0) do
      post :create, :copy => @tag, :name => "tag2", :overwrite => "true"
      assert_response :success
      assert_equal("'tag' successfully copied to 'tag2'", flash[:notice])
    end

    assert_equal [feed_item_1], tag2.taggings(:reload).map(&:feed_item)
  end
  
  def test_index
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
  def test_index_with_funny_name_tag
    Tagging.create(:user => users(:quentin), :tag => Tag(users(:quentin), 'tag.'), :feed_item => FeedItem.find(1))
    get :index
    assert_response :success
  end
  
  def test_edit_with_funny_name_tag
    tag_dot = Tag(users(:quentin), 'tag.')
    Tagging.create(:user => users(:quentin), :tag => tag_dot, :feed_item => FeedItem.find(1))
    get :edit, :id => tag_dot
    assert_response :success
  end
  
  def test_edit
    get :edit, :id => @tag
    assert assigns(:tag)
    assert_template 'edit'
  end
  
  def test_edit_with_missing_tag
    get :edit, :id => 'missing'
    assert_response 404
  end
  
  def test_edit_with_js
    accept('text/javascript')
    get :edit, :id => @tag
    assert assigns(:tag)
    assert_select "html", false
    assert_select "form[action='#{tag_path(@tag)}']", 1, @response.body
  end
  
  def test_tag_renaming_with_same_tag
    post :update, :id => @tag, :tag => {:name => 'tag' }
    assert_redirected_to tags_path
    assert_equal([@tag], users(:quentin).tags)
  end
  
  def test_tag_renaming
    post :update, :id => @tag, :tag => {:name => 'new'}
    assert_redirected_to tags_path
    assert users(:quentin).tags.find_by_name('new')
  end
  
  def test_tag_merging
    old = Tag(users(:quentin), 'old')
    Tagging.create(:user => users(:quentin), :tag => old, :feed_item => FeedItem.find(1))
    Tagging.create(:user => users(:quentin), :tag => old, :feed_item => FeedItem.find(2))
    Tagging.create(:user => users(:quentin), :tag => Tag(users(:quentin), 'new'), :feed_item => FeedItem.find(3))
    
    post :update, :id => old, :tag => {:name => 'new'}
    assert_redirected_to tags_path
    assert_equal("'old' merged with 'new'", flash[:notice])
  end
  
  def test_tag_merging_with_conflict
    old = Tag(users(:quentin), 'old')
    Tagging.create(:user => users(:quentin), :tag => old, :feed_item => FeedItem.find(1))
    Tagging.create(:user => users(:quentin), :tag => old, :feed_item => FeedItem.find(2))
    Tagging.create(:user => users(:quentin), :tag => Tag(users(:quentin), 'new'), :feed_item => FeedItem.find(2))
    
    post :update, :id => old, :tag => {:name => 'new'}
    assert_redirected_to tags_path
    assert_equal("'old' merged with 'new'", flash[:notice])
  end
  
  def test_destroy_by_tag
    login_as(:quentin)
    user = users(:quentin)
    to_destroy = Tag(user, 'to_destroy')
    to_keep = Tag(user, 'to_keep')
    user.taggings.create(:tag => to_destroy, :feed_item => FeedItem.find(1))
    user.taggings.create(:tag => to_destroy, :feed_item => FeedItem.find(2))
    user.taggings.create(:tag => to_destroy, :feed_item => FeedItem.find(3))
    keep = user.taggings.create(:tag => to_keep, :feed_item => FeedItem.find(1))
    
    assert_equal [@tag, to_destroy, to_keep], user.tags
    
    post :destroy, :id => to_destroy
    assert_response :success
    assert_equal [@tag, to_keep], users(:quentin).tags(true)
    assert_equal([@tagging, keep], user.taggings(true))
  end
  
  def test_destroy_by_tag_destroys_classifier_taggings
    login_as(:quentin)
    user = users(:quentin)
    to_destroy = Tag(user, 'to_destroy')
    to_keep = Tag(user, 'to_keep')
    
    user.taggings.create(:tag => to_destroy, :feed_item => FeedItem.find(1))
    user.taggings.create(:tag => to_destroy, :feed_item => FeedItem.find(2), :classifier_tagging => true)
    user.taggings.create(:tag => to_destroy, :feed_item => FeedItem.find(3), :classifier_tagging => true)
    keep = user.taggings.create(:tag => to_keep, :feed_item => FeedItem.find(1), :classifier_tagging => true)
    
    post :destroy, :id => to_destroy
    assert_response :success
    assert_equal [@tagging, keep], user.taggings(true)
    assert_equal [@tag, to_keep], user.tagging_tags(true)
  end
  
  def test_destroy_by_unused_tag
    login_as(:quentin)
    post :destroy, :id => 999999999
    assert_response 404
  end
  
  def test_atom_feed_contains_items_in_tag
    user = users(:quentin)
    tag = Tag(user, 'tag')
    tag.update_attribute :public, true
    
    user.taggings.create!(:feed_item => FeedItem.find(1), :tag => tag)
    user.taggings.create!(:feed_item => FeedItem.find(2), :tag => tag)

    get :show, :user_id => user.login, :id => tag, :format => "atom"

    assert_response(:success)
    assert_select("entry", 2, @response.body)
  end

  def test_atom_feed_with_missing_tag_returns_404
    get :show, :user_id => users(:quentin).login, :id => "missing", :format => "atom"
    assert_response(404)
  end

  def test_anyone_can_access_feeds
    login_as(nil)

    user = users(:quentin)
    tag = Tag(user, 'tag')
    tag.update_attribute :public, true

    get :show, :user_id => user.login, :id => tag, :format => "atom"
    assert_response :success
  end
  
  def test_subscribe_to_public_tag    
    other_user = users(:aaron)

    tag = Tag(other_user, 'hockey')
    tag.update_attribute :public, true
    
    TagSubscription.expects(:create!).with(:tag_id => tag.id, :user_id => users(:quentin).id)
    
    put :subscribe, :id => tag, :subscribe => "true"
    
    assert_response :success
  end
  
  # Test how unsubscribing as implemented on the "Public Tags" page
  def test_unsubscribe_from_public_tag_via_subscribe_action
    other_user = users(:aaron)

    tag = Tag(other_user, 'hockey')
    tag.update_attribute :public, true
    
    TagSubscription.expects(:delete_all).with(:tag_id => tag.id, :user_id => users(:quentin).id)
    
    put :subscribe, :id => tag, :subscribe => "false"
    
    assert_response :success
  end

  # Test unsubscribing as implemented on the "My Tags" page
  def test_unsubscribe_from_public_tag_via_unsubscribe_action
    referer("/tags")
    other_user = users(:aaron)

    tag = Tag(other_user, 'hockey')
    tag.update_attribute :public, true

    TagSubscription.expects(:delete_all).with(:tag_id => tag.id, :user_id => users(:quentin).id)

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
  def test_subscribe_to_other_users_tag_with_same_name
    other_user = users(:aaron)
    tag = Tag(other_user, 'tag')
    tag.update_attribute :public, true
    
    TagSubscription.expects(:create!).with(:tag_id => tag.id, :user_id => users(:quentin).id)
    
    put :subscribe, :id => tag, :subscribe => "true"
    
    assert_response :success
  end

  # SG: This ensures that only public tags can be subscribed to.
  # 
  def test_cant_subscribe_to_other_users_non_public_tags
    other_user = users(:aaron)
    tag = Tag(other_user, 'hockey')
    tag.update_attribute :public, false

    assert_no_difference(TagSubscription, :count) do
      put :subscribe, :id => tag, :subscribe => "true"
    end
    
    assert_response :success 
  end
end
