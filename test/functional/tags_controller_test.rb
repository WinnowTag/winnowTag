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

  def test_routing
    assert_routing('/tags/atag', :controller => 'tags', :action => 'show', :id => 'atag')
    assert_routing('/tags/my+tag', :controller => 'tags', :action => 'show', :id => 'my tag')
    assert_routing('/tags/edit/my+tag.', :controller => 'tags', :action => 'edit', :id => 'my tag.')
  end
  
  def test_create_should_copy_named_tag
    users(:quentin).taggings.create(:tag => @tag, :feed_item => FeedItem.find(1))
    assert_difference(users(:quentin).tags, :count) do
      post :create, :copy => 'tag'
      assert_redirected_to "/tags"
      assert_equal("'tag' successfully copied to 'tag - copy'", flash[:notice])
    end
    assert users(:quentin).tags.find(:first, :conditions => ['tags.name = ?', 'tag - copy'])
    assert_equal(2, users(:quentin).taggings.size)
  end
  
  def test_index
    get :index, :view_id => users(:quentin).views.create
    assert assigns(:tags)
    assert_equal(@tag, assigns(:tags).first)
    assert assigns(:classifier)
    assert_select "tr##{@tag.dom_id}", 1
    assert_select "tr##{@tag.dom_id} td:nth-child(1)", /tag.*/
    assert_select "tr##{@tag.dom_id} td:nth-child(5)", "1 / 0"
    assert_select "tr##{@tag.dom_id} td:nth-child(6)", "0"
  end
  
  # TODO - Tags with periods on the end break routing until Rails 1.2.4?
  def test_index_with_funny_name_tag
    Tagging.create(:user => users(:quentin), :tag => Tag(users(:quentin), 'tag.'), :feed_item => FeedItem.find(1))
    get :index, :view_id => users(:quentin).views.create
    assert_response :success
  end
  
  def test_edit_with_funny_name_tag
    Tagging.create(:user => users(:quentin), :tag => Tag(users(:quentin), 'tag.'), :feed_item => FeedItem.find(1))
    get :edit, :id => 'tag.', :view_id => users(:quentin).views.create
    assert_response :success
  end
  
  def test_edit
    get :edit, :id => 'tag', :view_id => users(:quentin).views.create
    assert assigns(:tag)
    assert_template 'edit'
  end
  
  def test_edit_with_missing_tag
    get :edit, :id => 'missing', :view_id => users(:quentin).views.create
    assert_response 404
  end
  
  def test_edit_with_js
    view = users(:quentin).views.create
    
    accept('text/javascript')
    get :edit, :id => 'tag', :view_id => view
    assert assigns(:tag)
    assert_select "html", false
    assert_select "form[action = '/tags/tag?view_id=#{view.id}']", 1, @response.body
  end
  
  def test_tag_renaming_with_same_tag
    view = users(:quentin).views.create
    
    post :update, :id => 'tag', :tag => {:name => 'tag' }, :view_id => view
    assert_redirected_to "/tags?view_id=#{view.id}"
    assert_equal([@tag], users(:quentin).tags)
  end
  
  def test_tag_renaming
    view = users(:quentin).views.create

    post :update, :id => 'tag', :tag => {:name => 'new'}, :view_id => view
    assert_redirected_to "/tags?view_id=#{view.id}"
    assert users(:quentin).tags.find_by_name('new')
  end
  
  def test_tag_merging
    view = users(:quentin).views.create
    
    Tagging.create(:user => users(:quentin), :tag => Tag(users(:quentin), 'old'), :feed_item => FeedItem.find(1))
    Tagging.create(:user => users(:quentin), :tag => Tag(users(:quentin), 'old'), :feed_item => FeedItem.find(2))
    Tagging.create(:user => users(:quentin), :tag => Tag(users(:quentin), 'new'), :feed_item => FeedItem.find(3))
    
    post :update, :id => 'old', :tag => {:name => 'new'}, :view_id => view
    assert_redirected_to "/tags?view_id=#{view.id}"
    assert_equal("'old' merged with 'new'", flash[:notice])
  end
  
  def test_tag_merging_with_conflict
    view = users(:quentin).views.create

    Tagging.create(:user => users(:quentin), :tag => Tag(users(:quentin), 'old'), :feed_item => FeedItem.find(1))
    Tagging.create(:user => users(:quentin), :tag => Tag(users(:quentin), 'old'), :feed_item => FeedItem.find(2))
    Tagging.create(:user => users(:quentin), :tag => Tag(users(:quentin), 'new'), :feed_item => FeedItem.find(2))
    
    post :update, :id => 'old',:tag => {:name => 'new'}, :view_id => view
    assert_redirected_to "/tags?view_id=#{view.id}"
    assert_equal("'old' merged with 'new'", flash[:notice])
  end
  
  def test_destroy_by_tag
    referer("/")
    login_as(:quentin)
    user = users(:quentin)
    to_destroy = Tag(user, 'to_destroy')
    to_keep = Tag(user, 'to_keep')
    user.taggings.create(:tag => to_destroy, :feed_item => FeedItem.find(1))
    user.taggings.create(:tag => to_destroy, :feed_item => FeedItem.find(2))
    user.taggings.create(:tag => to_destroy, :feed_item => FeedItem.find(3))
    keep = user.taggings.create(:tag => to_keep, :feed_item => FeedItem.find(1))
    
    assert_equal [@tag, to_destroy, to_keep], user.tags
    
    post :destroy, :id => 'to_destroy'
    assert_redirected_to '/'
    assert_equal [@tag, to_keep], users(:quentin).tags(true)
    assert_equal([@tagging, keep], user.taggings(true))
    assert_equal 'Deleted to_destroy.', flash[:notice]
  end
  
  def test_destroy_by_tag_destroys_classifier_taggings
    referer('/')
    login_as(:quentin)
    user = users(:quentin)
    to_destroy = Tag(user, 'to_destroy')
    to_keep = Tag(user, 'to_keep')
    
    user.taggings.create(:tag => to_destroy, :feed_item => FeedItem.find(1))
    user.taggings.create(:tag => to_destroy, :feed_item => FeedItem.find(2), :classifier_tagging => true)
    user.taggings.create(:tag => to_destroy, :feed_item => FeedItem.find(3), :classifier_tagging => true)
    keep = user.taggings.create(:tag => to_keep, :feed_item => FeedItem.find(1), :classifier_tagging => true)
    
    post :destroy, :id => 'to_destroy'
    assert_redirected_to '/'
    assert_equal [@tagging, keep], user.taggings(true)
    assert_equal [@tag, to_keep], user.tagging_tags(true)
    assert_equal 'Deleted to_destroy.', flash[:notice]
  end
  
  def test_destroy_by_unused_tag
    login_as(:quentin)
    post :destroy, :id => 'unused'
    assert_response 404
  end
  
  def test_atom_feed_contains_items_in_tag
    user = users(:quentin)
    tag = Tag(user, 'tag')
    tag.update_attribute :public, true
    
    user.taggings.create!(:feed_item => FeedItem.find(1), :tag => tag)
    user.taggings.create!(:feed_item => FeedItem.find(2), :tag => tag)

    get :show, :user_id => user.login, :id => tag.name, :format => "atom"

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

    get :show, :user_id => user.login, :id => tag.name, :format => "atom"
    assert_response :success
  end
  
  def test_subscribe_to_public_tag    
    other_user = users(:aaron)
    # Note: we must use a tag name other than the oft-used 'tag' to make this test pass. Finding a
    # tag by name only isn't sufficient, since tag names are unique by user, not globally.
    tag = Tag(other_user, 'hockey')
    tag.update_attribute :public, true
    
    TagSubscription.expects(:create!).with(:tag_id => tag.id, :user_id => users(:quentin).id)
    
    put :subscribe, :id => tag.name, :subscribe => true, :view_id => users(:quentin).views.create!
    
    assert_response :success
  end
  
  def test_unsubscribe_from_public_tag
    other_user = users(:aaron)
    # Note: we must use a tag name other than the oft-used 'tag' to make this test pass. Finding a
    # tag by name only isn't sufficient, since tag names are unique by user, not globally.
    tag = Tag(other_user, 'hockey')
    tag.update_attribute :public, true
    
    TagSubscription.expects(:delete_all).with(:tag_id => tag.id, :user_id => users(:quentin).id)
    
    put :subscribe, :id => tag.name, :subscribe => false, :view_id => users(:quentin).views.create!
    
    assert_response :success
  end
end
