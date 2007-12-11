require File.dirname(__FILE__) + '/../test_helper'
require 'feeds_controller'

# Re-raise errors caught by the controller and skip authentication.
class FeedsController; def rescue_action(e) raise e end; end

class FeedsControllerTest < Test::Unit::TestCase
  fixtures :feeds, :users, :roles, :roles_users
  
  def setup
    @controller = FeedsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_requires_login
    assert_requires_login {|c| c.get :index, {}}
  end
   
  def test_index_sets_feeds_instance_variable
    login_as(:quentin)
    get :index, :view_id => users(:quentin).views.create
    assert_equal(Feed.count, assigns(:feeds).size)
  end
  
  def test_index_shows_collection_result
    login_as(:quentin)
    job = users(:quentin).collection_job_results.create(:message => "Message", :feed_id => 1)
    get :index, :view_id => users(:quentin).views.create
    assert_select('div#notice', /Collection Job for #{job.feed.title} completed with result: Message/)
    job.reload
    assert job.user_notified?, "user_notified should be set to true after being displayed"
  end
  
  def test_index_shows_failed_collection_result
    login_as(:quentin)
    job = users(:quentin).collection_job_results.create(:message => "Message", :feed_id => 1, :failed => true)
    get :index, :view_id => users(:quentin).views.create
    assert_select('div#warning', /Collection Job for #{job.feed.title} failed with result: Message/)
    job.reload
    assert job.user_notified?, "user_notified should be set to true after being displayed"
  end
  
  def test_non_admin_can_see_list
    login_as(:quentin)
    get :index, :view_id => users(:quentin).views.create
    assert_response :success
  end
    
  def test_new_shows_form
    view = users(:quentin).views.create
    
    login_as(:quentin)
    get :new, :view_id => view
    assert_response :success
    assert_select("form[action='/feeds?view_id=#{view.id}']", 1, @response.body)
  end
  
  def test_create_uses_rest
    ActiveResource::HttpMock.respond_to do |mock|
      mock.post   "/feeds.xml",   {}, nil, 201, 'Location' => '/feeds/1'
      mock.post   "/feeds/1/collection_jobs.xml",   {}, nil, 201, 'Location' => '/feeds/1/collection_jobs/3'
    end

    login_as(:quentin)
    post :create, :feed => {:url => "http://newfeed.com"}
    assert_redirected_to feeds_url
    assert_equal("Added feed from 'http://newfeed.com'. " +
                  "Collection has been scheduled for this feed, " +
                  "we'll let you know when it's done.", flash[:notice])
    assert(assigns(:collection_job))
    assert_equal(users(:quentin).login, assigns(:collection_job).created_by)
    assert_equal(collection_job_results_url(users(:quentin)), assigns(:collection_job).callback_url)
  end
  
  def test_create_with_rest_error_shows_errors
    errors = ActiveResource::Errors.new(nil)
    errors.add(:url, "is invalid")
    Remote::Feed.expects(:new).
                 with('url' => '####').
                 returns(stub(:url => '####',
                              :save => false,
                              :errors => errors))
    login_as(:quentin)
    post :create, :feed => {:url => '####'}
    assert_response :success
    assert_select("div#error", true, @response.body)
  end
        
  def test_non_admin_can_show
    login_as(:quentin)
    get :show, :id => 1, :view_id => users(:quentin).views.create
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:feed)
  end
    
  def test_show_assigns_feed
    login_as(:admin)
    get :show, :id => 1, :view_id => users(:admin).views.create
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:feed)
    assert_equal Feed.find(1), assigns(:feed)
  end  
end
