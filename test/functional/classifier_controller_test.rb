require File.dirname(__FILE__) + '/../test_helper'
require 'classifier_controller'

# Re-raise errors caught by the controller.
class ClassifierController; def rescue_action(e) raise e end; end

class ClassifierControllerTest < Test::Unit::TestCase
  fixtures :users, :bayes_classifiers, :roles, :roles_users, :tag_publications
  
  def setup
    @controller = ClassifierController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def test_classify_requires_post
    login_as(:quentin)
    get :classify, :view_id => users(:quentin).views.create
    assert_response 400
  end
  
  def test_classifier_is_current_users
    login_as(:quentin)
    get :show, :view_id => users(:quentin).views.create
    assert_equal User.find_by_login('quentin').classifier, assigns(:classifier)
  end
  
  def test_tag_publication_scoped_routes
    assert_routing('/tag_publications/1/classifier', :controller => 'classifier', :action => "show", :tag_publication_id => '1')
    assert_routing('/tag_publications/3/classifier;status', :controller => 'classifier', :action => "status", :tag_publication_id => '3')
  end
  
  def test_classifier_tag_publications_when_tag_publication_id_is_set
    login_as(:admin)
    get :show, :tag_publication_id => 1, :view_id => users(:admin).views.create
    assert_equal(TagPublication.find(1).classifier, assigns(:classifier))
  end
  
  def test_classify_starts_background_process
    BayesClassifier.any_instance.stubs(:changed_tags).returns([Tag('tag')])
    MiddleMan.expects(:new_worker).with {|args|
                    args[:class] == :classification_worker and
                      args[:args] == {
                          :classifier => users(:quentin).classifier.id
                        }
                    }.returns('jobkey')
    
    login_as(:quentin)
    post :classify
    assert_response :redirect
    assert_redirected_to '/classifier/classification_status'
    assert_equal 'jobkey', BayesClassifier.find(users(:quentin).classifier.id).classifier_job.jobkey
  end
  
  def test_classify_prevents_two_process_from_running
    BayesClassifier.any_instance.stubs(:changed_tags).returns([Tag('tag')])
    MiddleMan.expects(:new_worker).returns("jobkey").once
    MiddleMan.expects(:[]).with("jobkey").returns(mock)
    
    login_as(:quentin)
    classifier = BayesClassifier.find(users(:quentin).classifier.id)
    classifier.create_classifier_job
    
    referer("/")
    post :classify
    assert_redirected_to "/"
    assert_equal "The classifier is already running.", flash[:error]
  end
  
  def test_classification_should_not_start_when_no_tags_have_changed
    MiddleMan.expects(:new_worker).never
    login_as(:quentin)
    BayesClassifier.any_instance.expects(:changed_tags).returns([])
    
    referer("/")
    post :classify
    assert_redirected_to "/"
    assert_equal("There are no changes to your tags", flash[:error])
  end
  
  def test_classify_with_stale_jobkey  
    BayesClassifier.any_instance.stubs(:changed_tags).returns([Tag('tag')])  
    MiddleMan.expects(:[]).with("stale_jobkey").raises
    MiddleMan.expects(:new_worker).returns('stale_jobkey','jobkey').times(2)
                    
    classifier = BayesClassifier.find(users(:quentin).classifier.id)
    classifier.create_classifier_job(:classifier_args => {:classifier => classifier.id})
        
    login_as(:quentin)
    post :classify
    assert_response :redirect
    assert_redirected_to '/classifier/classification_status'
    assert_nil flash[:error]
    assert_equal 'jobkey', BayesClassifier.find(users(:quentin).classifier.id).classifier_job.jobkey
  end
  
  def test_classification_status_action
    accept('text/x-json')
    login_as(:quentin)
    
    MiddleMan.expects(:[]).with("jobkey").returns(mock)
    MiddleMan.expects(:new_worker).returns("jobkey")
    
    progress = {:progress => 50, :progress_title => 'title', :progress_message => 'message'}
    classifier = BayesClassifier.find(users(:quentin).classifier.id)
    job = classifier.create_classifier_job(progress)
    job.reload 
        
    get :status, :view_id => users(:quentin).views.create
    assert_response :success
    assert_equal(job.attributes.to_json, @response.headers['X-JSON'])
  end
  
  def test_classification_status_action_when_not_running
    accept('text/x-json')
    login_as(:quentin)
        
    classifier = BayesClassifier.find(users(:quentin).classifier.id)
    classifier.classifier_job = nil
    classifier.save
    
    get :status, :view_id => users(:quentin).views.create
    assert_response 500
    assert_equal({:error_message => 'No classification process running', :progress => 100}.to_json, @response.headers['X-JSON'])
  end

  def test_cancel_classification
    login_as(:quentin)
    MiddleMan.expects(:new_worker).returns("jobkey")
    MiddleMan.expects(:[]).with('jobkey').returns(stub)
    MiddleMan.expects(:worker).with('jobkey').returns(mock(:cancel! => true))
    classifier = BayesClassifier.find(users(:quentin).classifier.id)
    classifier.create_classifier_job    
    
    post :cancel
    classifier.reload
    assert_nil classifier.current_job
  end
end
