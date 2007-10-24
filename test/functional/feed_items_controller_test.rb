require File.dirname(__FILE__) + '/../test_helper'
require 'feed_items_controller'

# Re-raise errors caught by the controller.
class FeedItemsController; def rescue_action(e) raise e end; end

class FeedItemsControllerTest < Test::Unit::TestCase
  fixtures :users, :feeds, :feed_items, :feed_item_contents, :tags, 
           :bayes_classifiers, :roles, :roles_users
  def setup
    @controller = FeedItemsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_requires_login
    assert_requires_login {|c| c.get :index, {}}
  end

  def test_html_show
    login_as :quentin
    get :show, :id => 1, :view_id => users(:quentin).views.create
    assert assigns(:user_tags_on_item)
    assert_response :success
  end
  
  def test_index
    login_as :quentin
    get :index, :view_id => users(:quentin).views.create
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:feed_items)
  end
    
  def test_index_with_tag_filtering
    user = users(:quentin)
    tag = Tag(user, 'peerworks')
    Tagging.create(:tag => tag, :user => user, :feed_item => FeedItem.find(1), :strength => 0)
    to_delete = Tagging.create(:tag => tag, :user => user, :feed_item => FeedItem.find(2), :strength => 1)
    # tag 3 with a different tag to make sure it doesnt come up
    Tagging.create(:tag => Tag(user, 'other'), :user => user, :feed_item => FeedItem.find(3), :strength => 1)

    login_as :quentin
    get :index, :tag_filter => tag.id, :view_id => users(:quentin).views.create
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:feed_items)
    assert assigns(:view).tag_filter[:include].include?(tag.id)
    
    # tag filter only work over positive taggings for M2
    assert_equal 1, assigns(:feed_items).size
    assert_equal 2, assigns(:feed_items)[0].id
    
    # Check reversed
    get :index, :tag_filter => tag.id, :view_id => users(:quentin).views.create
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:feed_items)
    assert assigns(:view).tag_filter[:include].include?(tag.id)
    assert_equal 1, assigns(:feed_items).size
    assert_equal 2, assigns(:feed_items).first.id
        
    # Check with tag_filter as tagged, should return all tagged items
    get :index, :view_id => users(:quentin).views.create
    assert_response :success
    assert_equal 2, assigns(:feed_items).size
    assert_equal [2, 3], assigns(:feed_items).map(&:id).sort
    
    # make sure deleted tags don't appear
    to_delete.destroy
    get :index, :tag_filter => tag.id, :view_id => users(:quentin).views.create
    assert_response :success
    assert_equal 0, assigns(:feed_items).size    
  end
  
  def test_index_with_ajax
    login_as(:quentin)
    accept('text/javascript')
    get :index, :offset => '1', :limit => '1', :view_id => users(:quentin).views.create, :show_untagged => true
    assert_response :success
    assert_equal 'text/javascript; charset=utf-8', @response.headers['Content-Type']
    assert_not_nil assigns(:feed_items)
    assert_nil assigns(:feeds)
    regex = /itemBrowser\.insertItem\("#{assigns(:feed_items).first.dom_id}", 1/
    assert @response.body =~ regex, "#{regex} does match #{@response.body}"
  end
  
  def test_index_filtered_by_tag_includes_classifier_tags
    login_as(:quentin)
    user = users(:quentin)    
    classifier = user.classifier
    tag = Tag(user, 'peerworks')
    Tagging.create(:tag => tag, :user => user, :feed_item => FeedItem.find(3), :strength => 1)
    Tagging.create(:tag => tag, :user => user, :feed_item => FeedItem.find(3), :strength => 0.95, :classifier_tagging => true)
    Tagging.create(:tag => tag, :user => user, :feed_item => FeedItem.find(4), :strength => 0.96, :classifier_tagging => true)
        
    # create classifier for another user - should never show
    other_tag = Tag(users(:aaron), 'peerworks')
    Tagging.create(:tag => other_tag, :user => users(:aaron), :feed_item => FeedItem.find(1), :strength => 0.91, :classifier_tagging => true)
    
    get :index, :tag_filter => tag.id, :view_id => users(:quentin).views.create
    assert_response :success
    assert_not_nil assigns(:feed_items)
    assert_equal 2, assigns(:feed_items).size
    assert_equal [3, 4], assigns(:feed_items).map(&:id).sort
    
    # now the classifier that tags 1 and 2 below the threshold, it should be ignored  
    Tagging.create(:tag => tag, :user => user, :feed_item => FeedItem.find(1), :strength => 0.4, :classifier_tagging => true)
    Tagging.create(:tag => tag, :user => user, :feed_item => FeedItem.find(2), :strength => 0.6, :classifier_tagging => true)
    get :index, :tag_filter => tag.id, :view_id => users(:quentin).views.create
    assert_response :success
    assert_not_nil assigns(:feed_items)
    assert_equal 2, assigns(:feed_items).size
    assert_equal [3, 4], assigns(:feed_items).map(&:id).sort
  end
  
  def test_negative_tagging_excluded_from_tag_filter
    login_as(:quentin)
    user = users(:quentin)
    classifier = user.classifier
    tag = Tag(user, 'tag1')
    fi1 = FeedItem.find(1)
    fi2 = FeedItem.find(2)
    
    Tagging.create(:tag => tag, :user => user, :feed_item => fi1, :strength => 0.95, :classifier_tagging => true)
    Tagging.create(:tag => tag, :user => user, :feed_item => fi2, :strength => 0.95, :classifier_tagging => true)
    Tagging.create(:tag => tag, :user => user, :feed_item => fi2, :strength => 0)
    
    get :index, :tag_filter => tag.id, :view_id => users(:quentin).views.create
    assert_response :success
    assert_not_nil assigns(:feed_items)
    assert_equal 1, assigns(:feed_items).size
    assert_equal 1, assigns(:feed_items).first.id
  end
  
  def test_negative_classifier_tagging_should_not_appear_in_moderation_panel
    login_as(:quentin)
    user = users(:quentin)
    classifier = user.classifier
    fi = FeedItem.find(1)
    Tagging.create(:tag => Tag(user, 'tag1'), :user => user, :feed_item => fi, :strength => 0.8, :classifier_tagging => true)
    
    accept('text/javascript')
    get :show, :id => 1
    assert_select("span#tag_control_for_tag1_on_feed_item_1.bayes_classifier_tagging.negative_tagging", false, @response.body)
  end
  
  def test_description
    accept('text/javascript')
    login_as(:quentin)
    get :description, :id => 1, :view_id => users(:quentin).views.create
    assert_response :success
    assert_rjs :replace_html, 'body_feed_item_1'
  end
  
  def test_info
    accept('text/javascript')
    login_as(:quentin)
    get :info, :id => 1, :view_id => users(:quentin).views.create
    assert_response :success
    assert_rjs :replace_html, 'tag_information_feed_item_1'
  end
  
  def test_info_with_user_tagging
    user = users(:quentin)
    user.taggings.create(:feed_item => FeedItem.find(1), :tag => Tag(user, 'tag'))
    BayesClassifier.any_instance.expects(:guess).returns({'tag' => [0.95, [[0.4,1]]]})
        
    accept('text/javascript')
    login_as(:quentin)
    get :info, :id => 1, :view_id => users(:quentin).views.create
    assert_select "h4[style= 'color: red;']", /tag - 0.9500/, @response.body
  end
  
  def test_info_with_classifier_tagging
    user = users(:quentin)
    user.taggings.create(:feed_item => FeedItem.find(1), :tag => Tag(user, 'tag'), :classifier_tagging => true)
    BayesClassifier.any_instance.expects(:guess).returns({'tag' => [0.95, [[0.4,1]]]})
        
    accept('text/javascript')
    login_as(:quentin)
    get :info, :id => 1, :view_id => users(:quentin).views.create
    assert_select "h4", /tag - 0.9500/, @response.body
    assert_select "h4[style= 'color: red;']", false, @response.body
  end
    
  def test_feed_filtering_assigns_the_feed_filter_to_the_view
    login_as(:quentin)
    get :index, :feed_filter => 1, :view_id => users(:quentin).views.create
    assert_response :success
    assert assigns(:feed_items)
    assert assigns(:view).feed_filter[:include].include?(1)
  end

  def test_session_storage_of_text_filter
    login_as(:quentin)
    get :index, :text_filter => "this is some text", :view_id => users(:quentin).views.create
    assert_equal("this is some text", assigns(:view).text_filter)
  end
  
  def test_changing_tag_filter_resets_text_filter
    login_as(:quentin)
    
    get :index, :text_filter => "text", :view_id => users(:quentin).views.create
    assert_not_nil(assigns(:view).text_filter)
    
    get :index, :tag_filter => 'all', :view_id => users(:quentin).views.create
    assert_nil(assigns(:view).text_filter)    
  end
  
  def test_removal_of_text_filter_when_blank
    login_as(:quentin)
    view = users(:quentin).views.create
    get :index, :text_filter => "text", :view_id => view
    get :index, :text_filter => "", :view_id => view
    assert_nil(assigns(:view).text_filter)
  end
  
  def test_removal_of_text_filter_when_nil
    login_as(:quentin)
    view = users(:quentin).views.create
    get :index, :text_filter => "text", :view_id => view
    get :index, :text_filter => nil, :view_id => view
    assert_nil(assigns(:view).text_filter)
  end
  
  def test_sets_last_accessed_time_on_each_request
    login_as(:quentin)
    user = User.find(users(:quentin).id)
    old_time = user.last_accessed_at = 1.minute.ago
    
    get :index, :view_id => users(:quentin).views.create
    assert_instance_of(Time, User.find(users(:quentin).id).last_accessed_at)
    assert(old_time < User.find(users(:quentin).id).last_accessed_at)
  end
  
  def test_mark_read
    users(:quentin).unread_items.create(:feed_item_id => 1)
    assert_difference(UnreadItem, :count, -1) do
      accept('text/javascript')
      login_as(:quentin)
      put :mark_read, :id => 1
      assert_response :success
      assert_rjs :replace_html, 'status_feed_item_1'
    end
  end
  
  def test_mark_many_read
    users(:quentin).unread_items.create(:feed_item_id => 1)
    users(:quentin).unread_items.create(:feed_item_id => 2)
    view = users(:quentin).views.create  :show_untagged => true
    assert_difference(UnreadItem, :count, -2) do
      accept('text/javascript')
      login_as(:quentin)
      put :mark_read, :view_id => view.id
      assert_response :success
    end
  end
  
  def test_mark_unread
    assert_difference(UnreadItem, :count, 1) do
      accept('text/javascript')
      login_as(:quentin)
      put :mark_unread, :id => 1
      assert_response :success
      assert_rjs :replace_html, 'status_feed_item_1'
    end
  end
end
