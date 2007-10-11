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
    @tag = Tag('tag')
    Tagging.create(:tagger => users(:quentin), :tag => @tag, :taggable => FeedItem.find(1))
  end

  def test_routing
    assert_routing('/tags/atag', :controller => 'tags', :action => 'show', :id => 'atag')
    assert_routing('/tags/my+tag', :controller => 'tags', :action => 'show', :id => 'my tag')
    assert_routing('/tags/edit/my+tag.', :controller => 'tags', :action => 'edit', :id => 'my tag.')
  end
  
  def test_create_should_copy_named_tag
    users(:quentin).taggings.create(:tag => Tag('tag'), :taggable => FeedItem.find(1))
    assert_difference(users(:quentin).tags, :count) do
      post :create, :copy => 'tag'
      assert_redirected_to "/tags"
    end
    assert users(:quentin).tags.find(:first, :conditions => ['tags.name = ?', 'Copy of tag'])
  end
  
  def test_index
    get :index, :view_id => users(:quentin).views.create
    assert assigns(:tags)
    assert_equal(@tag, assigns(:tags).first)
    assert assigns(:classifier)
    assert assigns(:classifier_counts)
    assert_select "tr##{@tag.dom_id}", 1
    assert_select "tr##{@tag.dom_id} td:nth-child(1)", /tag.*/
    assert_select "tr##{@tag.dom_id} td:nth-child(4)", "1 / 0"
    assert_select "tr##{@tag.dom_id} td:nth-child(5)", "0"
  end
  
  # TODO - Tags with periods on the end break routing until Rails 1.2.4?
  def test_index_with_funny_name_tag
    Tagging.create(:tagger => users(:quentin), :tag => Tag('tag.'), :taggable => FeedItem.find(1))
    get :index, :view_id => users(:quentin).views.create
    assert_response :success
  end
  
  def test_edit_with_funny_name_tag
    Tagging.create(:tagger => users(:quentin), :tag => Tag('tag.'), :taggable => FeedItem.find(1))
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
    accept('text/javascript')
    get :edit, :id => 'tag', :view_id => users(:quentin).views.create
    assert assigns(:tag)
    assert_select "html", false
    assert_select "form[action = '/tags/tag']", 1, @response.body
  end
  
  def test_tag_renaming_with_same_tag
    referer('/')
    accept('text/html')
    
    assert_equal 0, RenameTagging.count
    post :update, :id => 'tag', :tag => {:name => 'tag' }
    assert_equal 0, RenameTagging.count
    assert_redirected_to '/'
    assert_equal 'New tag cannot be the same as Old tag', flash[:error]
  end
  
  def test_tag_renaming
    referer('/')
    accept('text/html')
    
    assert_equal 0, RenameTagging.count
    post :update, :id => 'tag', :tag => {:name => 'new'}
    assert_redirected_to '/'
    assert_equal 1, RenameTagging.count
    assert_equal 'Renamed 1 tag from tag to new.', flash[:notice]
    rename = RenameTagging.find(:first)
    assert_equal Tag('tag'), rename.old_tag
    assert_equal Tag('new'), rename.new_tag
    assert_equal users(:quentin), rename.tagger
  end
  
  def test_tag_merging
    accept('text/html')
    referer('/')
    Tagging.create(:tagger => users(:quentin), :tag => Tag('tag'), :taggable => FeedItem.find(1))
    Tagging.create(:tagger => users(:quentin), :tag => Tag('tag'), :taggable => FeedItem.find(2))
    Tagging.create(:tagger => users(:quentin), :tag => Tag('new'), :taggable => FeedItem.find(2))
    
    assert_equal 0, RenameTagging.count
    post :update, :id => 'tag',:tag => {:name => 'new'}
    assert_redirected_to '/'
    assert_equal 1, RenameTagging.count
    assert_equal 'Renamed 1 tag from tag to new. Left 1 tag tag untouched because new already exists on the item.', flash[:notice]
    rename = RenameTagging.find(:first)
    assert_equal Tag('tag'), rename.old_tag
    assert_equal Tag('new'), rename.new_tag
    assert_equal users(:quentin), rename.tagger
  end
  
  def test_destroy_by_tag
    referer("/")
    login_as(:quentin)
    Tagging.create(:tagger => users(:quentin), :tag => Tag.find_or_create_by_name('to_destroy'), :taggable => FeedItem.find(1))
    Tagging.create(:tagger => users(:quentin), :tag => Tag.find_or_create_by_name('to_destroy'), :taggable => FeedItem.find(2))
    Tagging.create(:tagger => users(:quentin), :tag => Tag.find_or_create_by_name('to_destroy'), :taggable => FeedItem.find(3))
    Tagging.create(:tagger => users(:quentin), :tag => Tag.find_or_create_by_name('to_keep'), :taggable => FeedItem.find(1))
    
    assert_equal [@tag, Tag.find_by_name('to_destroy'), Tag.find_by_name('to_keep')], users(:quentin).tags
    
    post :destroy, :id => 'to_destroy'
    assert_redirected_to '/'
    assert_equal [@tag, Tag.find_by_name('to_keep')], users(:quentin).tags(true)
    assert_equal 'Deleted 3 uses of to_destroy.', flash[:notice]
  end
  
  def test_destroy_by_tag_destroys_classifier_taggings
    referer('/')
    login_as(:quentin)
    Tagging.create(:tagger => users(:quentin), :tag => Tag.find_or_create_by_name('to_destroy'), :taggable => FeedItem.find(1))
    Tagging.create(:tagger => users(:quentin).classifier, :tag => Tag.find_or_create_by_name('to_destroy'), :taggable => FeedItem.find(2))
    Tagging.create(:tagger => users(:quentin).classifier, :tag => Tag.find_or_create_by_name('to_destroy'), :taggable => FeedItem.find(3))
    Tagging.create(:tagger => users(:quentin).classifier, :tag => Tag.find_or_create_by_name('to_keep'), :taggable => FeedItem.find(1))
    
    post :destroy, :id => 'to_destroy'
    assert_redirected_to '/'
    assert_equal 1, users(:quentin).classifier.taggings.size
    assert_equal [Tag.find_by_name('to_keep')], users(:quentin).classifier.tags(true)
    assert_equal 'Deleted 1 use of to_destroy.', flash[:notice]
  end
  
  def test_destroy_by_unused_tag
    login_as(:quentin)
    post :destroy, :id => 'unused'
    assert_response 404
  end
end
