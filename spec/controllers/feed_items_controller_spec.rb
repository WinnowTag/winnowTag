require File.dirname(__FILE__) + '/../spec_helper'

describe FeedItemsController do
  fixtures :users, :feeds, :feed_items, :tags

  it "requires_login" do
    assert_requires_login {|c| c.get :index, {}}
  end

  it "index" do
    login_as :quentin
    get :index
    assert_response :success
    assert_template 'index'
  end
  
  it "index_with_ajax" do
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
    
  it "/description" do
    login_as(:quentin)
    get :description, :id => 1, :format => "js"
    assert_response :success
    # TODO: Move the view test
    # assert_rjs :replace_html, 'body_feed_item_1'
  end
  
  # TODO: Fix to use C classifier
  # it "info" do
  #     accept('text/javascript')
  #     login_as(:quentin)
  #     get :info, :id => 1
  #     assert_response :success
  #     assert_rjs :replace_html, 'tag_information_feed_item_1'
  #   end
  #   
  #   it "info_with_user_tagging" do
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
  #   it "info_with_classifier_tagging" do
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
    
  it "sets_last_accessed_time_on_each_request" do
    login_as(:quentin)
    user = User.find(users(:quentin).id)
    old_time = user.last_accessed_at = 1.minute.ago
    
    get :index
    assert_instance_of(Time, User.find(users(:quentin).id).last_accessed_at)
    assert(old_time < User.find(users(:quentin).id).last_accessed_at)
  end
  
  it "mark_read" do
    assert_difference("ReadItem.count", 1) do
      login_as(:quentin)
      put :mark_read, :id => 1, :format => "js"
      assert_response :success
    end
  end
  
  it "mark_read_twice_only_creates_one_entry_and_doesnt_fail" do
    assert_difference("ReadItem.count", 1) do
      login_as(:quentin)
      put :mark_read, :id => 1, :format => "js"
      assert_response :success
      put :mark_read, :id => 1, :format => "js"
      assert_response :success
    end
  end
  
  it "mark_many_read" do
    users(:quentin).read_items.create(:feed_item_id => 1)
    users(:quentin).read_items.create(:feed_item_id => 2)
    assert_difference("ReadItem.count", 2) do
      login_as(:quentin)
      put :mark_read, :format => "js"
      assert_response :success
    end
  end
  
  it "mark_unread" do
    users(:quentin).read_items.create(:feed_item_id => 2)
    assert_difference("ReadItem.count", -1) do
      login_as(:quentin)
      put :mark_unread, :id => 2, :format => "js"
      assert_response :success
    end
  end
end
