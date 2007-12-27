require File.dirname(__FILE__) + '/../test_helper'
require 'taggings_controller'

# Re-raise errors caught by the controller.
class TaggingsController; def rescue_action(e) raise e end; end

class TaggingsControllerTest < Test::Unit::TestCase
  fixtures :users, :feed_items, :tags, :taggings
  def setup
    @controller = TaggingsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.env['HTTP_REFERER'] = '/feed_items'
  end

  def test_create_requires_post
    login_as(:quentin)
    get :create
    assert_response 400
  end
  
  def test_destroy_requires_post
    login_as(:quentin)
    get :destroy
    assert_response 400
  end
  
  def assert_all_actions_require_login
    assert_requires_login do |c|
      c.get :create
      c.get :destroy
    end
  end
    
  def test_create_without_parameters_fails
    login_as(:quentin)
    post :create, {}
    assert_response 400
  end
  
  def test_create_without_tag_doesnt_create_tagging
    login_as(:quentin)
    assert_no_difference(Tagging, :count) do
      post :create, :tagging => {:feed_item_id => '1'}
    end
  end
  
  def test_create_with_blank_tag_doesnt_create_tagging
    login_as(:quentin)
    assert_no_difference(Tagging, :count) do
      post :create, :tagging => {:feed_item_id => '1', :tag => ''}
    end
  end
  
  def test_create_with_other_user_fails
    login_as(:aaron)
    tag = Tag(users(:aaron), 'peerworks')
    accept('text/javascript')
    post :create, {:tagging => {:feed_item_id => 1, :tag => 'peerworks'}}
                
    assert_nil Tagging.find(:first, :conditions => ["user_id = 1 and feed_item_id = 1 and tag_id = ?", tag.id])
  end
  
  def test_create_tagging_with_strength_zero
    accept('text/javascript')
    login_as(:quentin)
    tag = Tag(users(:quentin), 'peerworks')
    
    assert_nil Tagging.find(:first, :conditions => 
                                        ["user_id = 1 and feed_item_id = 1 and strength = 0 and " + 
                                          "tag_id = ?", tag.id])
                                          
    assert_difference(users(:quentin).taggings, :count) do                                                    
      post :create, {:tagging => {:strength => '0', :feed_item_id => 1, :tag => 'peerworks'}}
    end
    
    assert_not_nil Tagging.find(:first, :conditions => 
                                          ["user_id = 1 and feed_item_id = 1 and strength = 0 and " + 
                                            "tag_id = ?", tag.id])
  end
      
  def test_destroy_tagging_specified_by_taggable_and_tag_name_with_ajax
    tagger = User.find(1)
    tag = Tag(tagger, 'peerworks')
    taggable = FeedItem.find(1)
    tagging = Tagging.create(:feed_item => taggable, :user => tagger, :tag => tag)

    accept('text/javascript')
    login_as(:quentin)
    post :destroy, :tagging => {:feed_item_id => '1', :tag => 'peerworks'}
    assert_template 'destroy'
    assert_raise (ActiveRecord::RecordNotFound) {Tagging.find(tagging.id)}
  end
  
  def test_destroy_does_not_destroy_classifier_taggings
    login_as(:quentin)

    user = User.find(1)
    tag = Tag(user, 'peerworks')
    feed_item = FeedItem.find(1)
    tagging = Tagging.create!(:feed_item => feed_item, :user => user, :tag => tag)
    tagging = Tagging.create!(:feed_item => feed_item, :user => user, :tag => tag, :classifier_tagging => true)

    assert_equal 2, Tagging.count
    
    accept('text/javascript')
    post :destroy, :tagging => {:feed_item_id => '1', :tag => 'peerworks'}

    assert_equal 1, Tagging.count
  end
end
