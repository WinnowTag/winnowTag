require File.dirname(__FILE__) + '/../test_helper'
require 'taggings_controller'

# Re-raise errors caught by the controller.
class TaggingsController; def rescue_action(e) raise e end; end

class TaggingsControllerTest < Test::Unit::TestCase
  fixtures :users, :feed_items, :tags, :taggings, :bayes_classifiers
  def setup
    @controller = TaggingsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.env['HTTP_REFERER'] = '/feed_items'
    MiddleMan.stubs(:worker).returns(stub_everything)
  end

  def test_create_requires_post
    login_as(:quentin)
    get :create, :view_id => users(:quentin).views.create
    assert_response 400
  end
  
  def test_destroy_requires_post
    login_as(:quentin)
    get :destroy, :view_id => users(:quentin).views.create
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
      post :create, :tagging => {:taggable_type => 'Feed', :taggable_id => '1'}
    end
  end
  
  def test_create_with_blank_tag_doesnt_create_tagging
    login_as(:quentin)
    assert_no_difference(Tagging, :count) do
      post :create, :tagging => {:taggable_type => 'Feed', :taggable_id => '1', :tag => ''}
    end
  end
  
  def test_create_with_other_user_fails
    login_as(:aaron)
    Tag.create(:name => 'peerworks')
    accept('text/html')
    post :create, {:tagging => {:tagger_id => 1, :tagger_type => 'User', 
                              :taggable_id => 1, :taggable_type => 'FeedItem', :tag => 'peerworks'}}
                
    assert_nil Tagging.find(:first, :conditions => ["tagger_id = 1 and tagger_type = 'User' and taggable_id = 1 and " + 
                                                        "taggable_type = 'FeedItem' and tag_id = ?", Tag.find_by_name('peerworks').id])
  end
  
  def test_create_tagging_accept_html_redirects_to_referrer
    accept('text/html')
    login_as(:quentin)
    assert_nil Tagging.find(:first, :conditions => ["tagger_id = 1 and tagger_type = 'User' and taggable_id = 1 and strength = 1 and " + 
                                                        "taggable_type = 'FeedItem' and tag_id = ?", Tag.find_by_name('peerworks').id])
    post :create, {:tagging => {:tagger_id => 1, :tagger_type => 'User', :strength => '1',
                              :taggable_id => 1, :taggable_type => 'FeedItem', :tag => 'peerworks'}}
    assert_redirected_to '/feed_items'
    assert_not_nil Tagging.find(:first, :conditions => ["tagger_id = 1 and tagger_type = 'User' and taggable_id = 1 and strength = 1 and " + 
                                                        "taggable_type = 'FeedItem' and tag_id = ?", Tag.find_by_name('peerworks').id])
  end
  
  def test_create_tagging_with_strength_zero
    accept('text/html')
    login_as(:quentin)
    assert_nil Tagging.find(:first, :conditions => ["tagger_id = 1 and tagger_type = 'User' and taggable_id = 1 and strength = 0 and " + 
                                                        "taggable_type = 'FeedItem' and tag_id = ?", Tag.find_by_name('peerworks').id])
    post :create, {:tagging => {:tagger_id => 1, :tagger_type => 'User', :strength => '0',
                              :taggable_id => 1, :taggable_type => 'FeedItem', :tag => 'peerworks'}}
    assert_redirected_to '/feed_items'
    assert_not_nil Tagging.find(:first, :conditions => ["tagger_id = 1 and tagger_type = 'User' and taggable_id = 1 and strength = 0 and " + 
                                                        "taggable_type = 'FeedItem' and tag_id = ?", Tag.find_by_name('peerworks').id])
  end
      
  def test_destroy_tagging_specified_by_taggable_and_tag_name
    tagger = User.find(1)
    tag = Tag.find_or_create_by_name('peerworks')
    taggable = FeedItem.find(1)
    tagging = Tagging.create(:taggable => taggable, :tagger => tagger, :tag => tag)
    accept('text/html')
    login_as(:quentin)
    post :destroy, :tagging => {:taggable_type => 'FeedItem', :taggable_id => '1', :tag => 'peerworks'}
    assert_redirected_to '/feed_items'
    assert_raise (ActiveRecord::RecordNotFound) {Tagging.find(tagging.id)}
  end
  
  def test_destroy_tagging_specified_by_taggable_and_tag_name_with_ajax
    tagger = User.find(1)
    tag = Tag.find_or_create_by_name('peerworks')
    taggable = FeedItem.find(1)
    tagging = Tagging.create(:taggable => taggable, :tagger => tagger, :tag => tag)

    accept('text/javascript')
    login_as(:quentin)
    post :destroy, :tagging => {:taggable_type => 'FeedItem', :taggable_id => '1', :tag => 'peerworks'}
    assert_template 'feed_items/tags_updated.rjs'
    assert_raise (ActiveRecord::RecordNotFound) {Tagging.find(tagging.id)}
  end
  
  private
  def load_tagging(tag)
    Tagging.find(:first, :conditions => ["tagger_id = 1 and tagger_type = 'User' and taggable_id = 1 and " + 
                                          "taggable_type = 'FeedItem' and tag_id = ?", Tag.find_by_name(tag).id])
  end
end
