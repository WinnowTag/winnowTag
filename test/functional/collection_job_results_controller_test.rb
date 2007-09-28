require File.dirname(__FILE__) + '/../test_helper'
require 'collection_job_results_controller'

# Re-raise errors caught by the controller.
class CollectionJobResultsController; def rescue_action(e) raise e end; end

class CollectionJobResultsControllerTest < Test::Unit::TestCase
  fixtures :collection_job_results, :users

  def setup
    @controller = CollectionJobResultsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as(:quentin)
  end

  def test_should_get_index
    get :index, :user_id => users(:quentin).id, :view_id => users(:quentin).views.create
    assert_response :success
    assert_equal(CollectionJobResult.find_all_by_user_id(users(:quentin).id), assigns(:collection_job_results))
  end

  def test_should_create_collection_job_result
    old_count = CollectionJobResult.count
    post :create, :collection_job_result => { }, :user_id => users(:quentin).id
    assert_equal old_count+1, CollectionJobResult.count
    
    assert_response :created
    assert_equal(collection_job_result_url(users(:quentin), assigns(:collection_job_result)), @response.headers['Location'])
  end
  
  def test_should_create_collection_job_result_from_remote_collection_job
    old_count = CollectionJobResult.count
    post :create, :collection_job => { :feed_id => 1, :failed => false, :message => "Message", :item_count => 10}, 
                  :user_id => users(:quentin).id
    assert_equal old_count+1, CollectionJobResult.count
    assert_equal(1, assigns(:collection_job_result).feed_id)
    assert_equal("Message", assigns(:collection_job_result).message)
    assert_equal(false, assigns(:collection_job_result).failed)
  end
  
  def test_can_create_without_login_from_local
    @controller.stubs(:local_request?).returns(true)
    @request.session[:user] = nil
    post :create, :collection_job_result => { }, :user_id => users(:quentin).id
    assert_response :created
  end

  def test_should_show_collection_job_result
    get :show, :id => 1, :user_id => users(:quentin).id, :view_id => users(:quentin).views.create
    assert_response :success
  end
end
