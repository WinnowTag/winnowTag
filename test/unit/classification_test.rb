require File.dirname(__FILE__) + '/../test_helper'
$: << RAILS_ROOT + '/vendor/plugins/backgroundrb/server/lib'
require 'backgroundrb/middleman'
require 'backgroundrb/worker_rails'
require 'workers/classification_worker'

# Stub out worker initialization to keep it in-process
class BackgrounDRb::Worker::RailsBase
  def initialize(args = nil, jobkey = nil); end
  def jobkey; "job_key"; end
  # override delete so it doesn't end the process
  def delete; end
end

class ClassificationTest < Test::Unit::TestCase
  fixtures :feed_items, :users, :bayes_classifiers, :tags
  
  def setup
    MiddleMan.expects(:new_worker).returns("job_key")
    BayesClassifier.find(1).create_classifier_job(:jobkey => "job_key")    
  end
  
  def test_classification_execution
    setup_mocks
    worker = ClassificationWorker.new
    worker.do_work(:classifier => 1)

    job = BayesClassifier.find(1).classifier_job
    assert_nil job.error_message
    assert_equal 100, job.progress
    assert_equal 'Classification Complete', job.progress_message
    assert job.complete?
  end
  
  def test_classification_uses_tags_modified_since_last_run
    BayesClassifier.any_instance.expects(:changed_tags).returns([Tag('tag1'), Tag('tag2')])
    BayesClassifier.any_instance.expects(:classify_all).with(has_entry(:only, ['tag1', 'tag2']))
    ClassificationWorker.new.do_work(:classifier => 1)
  end
  
  def test_classification_execution_with_limit_on_number_of_items
    fi1 = FeedItem.find(1)    
  
    FeedItem.expects(:each_with_index).with{|o| o[:limit] == 1}.yields(fi1, 1)
    BayesClassifier.any_instance.expects(:update_training)
    BayesClassifier.any_instance.expects(:classify).with {|*args| args.first == fi1}
    
    
    worker = ClassificationWorker.new
    worker.do_work(:classifier => 1, :limit => 1)
    assert BayesClassifier.find(1).classifier_job.complete?
  end
  
  def test_classification_without_classifier_throws_error
    worker = ClassificationWorker.new
    assert_raise(ArgumentError) { worker.do_work({}) }
    job = BayesClassifier.find(1).classifier_job
    assert_nil job.error_message
    assert_equal(false, job.complete?)
    assert_equal(false, job.failed?)
  end
  
  def test_mismatching_job_keys_bails_out
    BayesClassifier.any_instance.expects(:update_training).never
    BayesClassifier.any_instance.expects(:classify).never
    worker = ClassificationWorker.new
    worker.stubs(:jobkey).returns("different key")
    worker.do_work(:classifier => 1)
    
    # make sure the job is untouched
    job = BayesClassifier.find(1).classifier_job
    assert_equal(false, job.complete?)
    assert_equal(0, job.progress)
  end
  
  def test_worker_deletes_itself_when_successful
    setup_mocks
    worker = ClassificationWorker.new
    worker.expects(:delete)
    worker.do_work(:classifier => 1)
  end
  
  private
  def setup_mocks
    fi1 = FeedItem.find(1)
    fi2 = FeedItem.find(2)
    
    BayesClassifier.any_instance.expects(:update_training)
    BayesClassifier.any_instance.expects(:classify).with {|*args| args.first == fi1}
    BayesClassifier.any_instance.expects(:classify).with {|*args| args.first == fi2}
    
    FeedItem.expects(:each_with_index).multiple_yields([fi1, 1],[fi2, 2])
  end
end
