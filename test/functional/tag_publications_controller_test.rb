require File.dirname(__FILE__) + '/../test_helper'
require 'tag_publications_controller'

# Re-raise errors caught by the controller.
class TagPublicationsController; def rescue_action(e) raise e end; end

class TagPublicationsControllerTest < Test::Unit::TestCase
  fixtures :tag_publications, :users, :tags

  def setup
    @controller = TagPublicationsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as(:quentin)
  end
  
  def test_new_for_user_produces_tag_publication_creation_form
    accept("text/javascript")
    get :new, :user_id => 'quentin', :tag_publication => {:tag => 'tag'}, :view_id => users(:quentin).views.create
    assert_response :success
    assert_select("form[action = '/users/quentin/tag_publications'][method = 'post']", true, @response.body)
    assert_select("input[type = 'hidden'][name = 'tag_publication[tag_id]'][value = '#{Tag('tag').id}']", true, @response.body)
  end
  
  def test_create_tag_publication
    MiddleMan.expects(:new_worker)
    assert_difference(users(:quentin).tag_publications, :count) do
      referer("/")
      post :create, :user_id => 'quentin', :tag_publication => {:tag_id => Tag('new').id, :comment => 'comment'}
    end
  end
  
  def test_create_tag_publication_overwrite_existing
    assert_difference(TagPublication, :count, 0) do 
      referer("/")
      post :create, :user_id => 'quentin', :tag_publication => {:tag_id => 1, :comment => 'new version'}
    end
  end
  
  def test_atom_feed_contains_items_in_tag
    users(:quentin).taggings.create(:taggable => FeedItem.find(1), :tag => Tag('tag'))
    users(:quentin).taggings.create(:taggable => FeedItem.find(2), :tag => Tag('tag'))
    tp = users(:quentin).tag_publications.create(:tag => Tag('tag'))

    get :show, :id => tp.tag.name, :user_id => users(:quentin).login
    assert_response(:success)
    assert_select("entry", 2, @response.body)
  end
  
  def test_atom_feed_with_missing_tag_returns_404
    get :show, :id => 'blah', :user_id => users(:quentin).login
    assert_response(404)
  end
  
  def test_anyone_can_access_feeds
    login_as(nil)
    get :show, :id => users(:quentin).tag_publications.first.tag.name, :user_id => users(:quentin).login
    assert_response :success
  end
    
  def test_destroy_tag_publication_from_publisher
    publisher = users(:quentin)
    assert_difference(publisher.tag_publications, :count, -1) do
      referer("/")
      post :destroy, :user_id => publisher.login, :id => publisher.tag_publications.first.id
    end
  end
end
