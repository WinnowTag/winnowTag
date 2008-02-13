require File.dirname(__FILE__) + '/../spec_helper'

describe FeedItemsController do
  fixtures :users, :feeds, :feed_items, :tags

  def test_requires_login
    assert_requires_login {|c| c.get :index, {}}
  end

  # TODO: Fix to work with C classifier
  # def test_html_show
  #   login_as :quentin
  #   get :show, :id => 1
  #   assert assigns(:user_tags_on_item)
  #   assert_response :success
  # end
  
  def test_index
    login_as :quentin
    get :index
    assert_response :success
    assert_template 'index'
  end
  
  def test_index_with_ajax
    login_as(:quentin)
    get :index, :offset => '1', :limit => '1', :show_untagged => true, :format => "js"
    assert_response :success
    assert_equal 'text/javascript; charset=utf-8', @response.headers['type']
    assert_not_nil assigns(:feed_items)
    assert_nil assigns(:feeds)
    # TODO: Move this test to a view test
    # regex = /itemBrowser\.insertItem\("#{dom_id(assigns(:feed_items).first)}", 1/
    # assert @response.body =~ regex, "#{regex} does match #{@response.body}"
  end
  
  def test_negative_classifier_tagging_should_not_appear_in_moderation_panel
    login_as(:quentin)
    user = users(:quentin)
    fi = FeedItem.find(1)
    Tagging.create(:tag => Tag(user, 'tag1'), :user => user, :feed_item => fi, :strength => 0.8, :classifier_tagging => true)
    
    get :show, :id => 1, :format => "js"
    assert_select("span#tag_control_for_tag1_on_feed_item_1.negative.classifier", false, @response.body)
  end
  
  it "/description" do
    login_as(:quentin)
    get :description, :id => 1, :format => "js"
    assert_response :success
    # TODO: Move the view test
    # assert_rjs :replace_html, 'body_feed_item_1'
  end
  
  # TODO: Fix to use C classifier
  # def test_info
  #     accept('text/javascript')
  #     login_as(:quentin)
  #     get :info, :id => 1
  #     assert_response :success
  #     assert_rjs :replace_html, 'tag_information_feed_item_1'
  #   end
  #   
  #   def test_info_with_user_tagging
  #     user = users(:quentin)
  #     user.taggings.create(:feed_item => FeedItem.find(1), :tag => Tag(user, 'tag'))
  #     BayesClassifier.any_instance.expects(:guess).returns({'tag' => [0.95, [[0.4,1]]]})
  #         
  #     accept('text/javascript')
  #     login_as(:quentin)
  #     get :info, :id => 1
  #     assert_select "h4[style= 'color: red;']", /tag - 0.9500/, @response.body
  #   end
  #   
  #   def test_info_with_classifier_tagging
  #     user = users(:quentin)
  #     user.taggings.create(:feed_item => FeedItem.find(1), :tag => Tag(user, 'tag'), :classifier_tagging => true)
  #     BayesClassifier.any_instance.expects(:guess).returns({'tag' => [0.95, [[0.4,1]]]})
  #         
  #     accept('text/javascript')
  #     login_as(:quentin)
  #     get :info, :id => 1
  #     assert_select "h4", /tag - 0.9500/, @response.body
  #     assert_select "h4[style= 'color: red;']", false, @response.body
  #   end
    
  def test_sets_last_accessed_time_on_each_request
    login_as(:quentin)
    user = User.find(users(:quentin).id)
    old_time = user.last_accessed_at = 1.minute.ago
    
    get :index
    assert_instance_of(Time, User.find(users(:quentin).id).last_accessed_at)
    assert(old_time < User.find(users(:quentin).id).last_accessed_at)
  end
  
  def test_mark_read
    assert_difference("ReadItem.count", 1) do
      login_as(:quentin)
      put :mark_read, :id => 1, :format => "js"
      assert_response :success
    end
  end
  
  def test_mark_many_read
    users(:quentin).read_items.create(:feed_item_id => 1)
    users(:quentin).read_items.create(:feed_item_id => 2)
    assert_difference("ReadItem.count", 2) do
      login_as(:quentin)
      put :mark_read, :format => "js"
      assert_response :success
    end
  end
  
  def test_mark_unread
    users(:quentin).read_items.create(:feed_item_id => 2)
    assert_difference("ReadItem.count", -1) do
      login_as(:quentin)
      put :mark_unread, :id => 2, :format => "js"
      assert_response :success
    end
  end
end
