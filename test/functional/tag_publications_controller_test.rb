require File.dirname(__FILE__) + '/../test_helper'
require 'tag_publications_controller'

# Re-raise errors caught by the controller.
class TagPublicationsController; def rescue_action(e) raise e end; end

class TagPublicationsControllerTest < Test::Unit::TestCase
  fixtures :tag_publications, :tag_groups, :users, :tags

  def setup
    @controller = TagPublicationsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as(:quentin)
  end

  # Replace this with your real tests.
  def test_index_for_tag_group
    get :index, :tag_group_id => 1, :view_id => users(:quentin).views.create
    assert_not_nil(assigns(:tag_publications))
    assert_equal(TagGroup.find(1).tag_publications.size, assigns(:tag_publications).size)
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
      post :create, :user_id => 'quentin', :tag_publication => {:tag_id => Tag('new').id, :tag_group_id => 1, :comment => 'comment'}
    end
  end
  
  def test_create_tag_publication_overwrite_existing
    assert_difference(TagPublication, :count, 0) do 
      referer("/")
      post :create, :user_id => 'quentin', :tag_publication => {:tag_id => 1, :tag_group_id => 1, :comment => 'new version'}
    end
  end
  
  def test_destroy_tag_publication_from_tag_group
    login_as(:admin)
    tag_group = TagGroup.find(1)
    assert_difference(tag_group.tag_publications, :count, -1) do
      referer("/")
      post :destroy, :tag_group_id => tag_group.id, :id => tag_group.tag_publications.first.id
    end    
  end
  
  def test_destroy_tag_publication_from_tag_group_requires_admin
    tag_group = TagGroup.find(1)
    assert_no_difference(tag_group.tag_publications, :count) do
      referer("/")
      post :destroy, :tag_group_id => tag_group.id, :id => tag_group.tag_publications.first.id
    end    
  end
  
  def test_destroy_tag_publication_from_publisher
    publisher = users(:quentin)
    assert_difference(publisher.tag_publications, :count, -1) do
      referer("/")
      post :destroy, :user_id => publisher.login, :id => publisher.tag_publications.first.id
    end
  end
end
