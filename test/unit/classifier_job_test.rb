# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'

class ClassifierJobTest < Test::Unit::TestCase
  fixtures :bayes_classifiers, :classifier_jobs

  def test_default_progress_is_zero
    assert_equal(0, ClassifierJob.new.progress)
  end
  
  def test_default_progress_title
    assert_equal("Starting Classifier", ClassifierJob.new.progress_title)
  end
  
  def test_default_is_not_failed
    assert_equal(false, ClassifierJob.new.failed?)    
  end
  
  def test_default_is_not_complete
    assert_equal(false, ClassifierJob.new.complete?)
  end
  
  def test_cancel_calls_cancel_on_worker
    MiddleMan.expects(:new_worker).returns("jobkey")
    MiddleMan.expects(:worker).with("jobkey").returns(mock(:cancel! => true))
    job = ClassifierJob.create
    job.cancel!
  end
  
  def test_cancel_sets_complete
    MiddleMan.expects(:new_worker).returns("jobkey")
    job = ClassifierJob.create
    job.cancel!
    assert_equal(true, job.complete?)
  end
    
  def test_start_background_process_sets_jobkey
    MiddleMan.expects(:new_worker).with({:class => :classification_worker, 
                                         :args => {
                                           :classifier => 1
                                         }}).returns('jobkey')
    classifier = BayesClassifier.find(1)
    assert_nothing_raised(Exception) { classifier.start_background_classification }
    assert_equal('jobkey', classifier.classifier_job.jobkey)
  end
  
  def test_start_background_process_with_stale_jobkey_starts_new_process
    MiddleMan.expects(:[]).with("stale_jobkey").raises
    MiddleMan.expects(:new_worker).with(
                    {:class => :classification_worker,
                     :args => {
                          :classifier => 1
                        }
                      }
                    ).returns('jobkey')
    classifier = BayesClassifier.find(1)
    classifier.build_classifier_job(:jobkey => 'stale_jobkey')
    assert_nothing_raised(Exception) { classifier.start_background_classification }
    assert_equal('jobkey', classifier.classifier_job.jobkey)    
  end
  
  def test_start_background_process_prevents_two_process_from_running
    MiddleMan.expects(:new_worker).never
    MiddleMan.expects(:[]).with("jobkey").returns(mock)
    
    classifier = BayesClassifier.find(1)
    classifier.build_classifier_job(:jobkey => 'jobkey')
    assert_raise(BayesClassifier::ClassifierAlreadyRunning) { 
      begin
        classifier.start_background_classification 
      rescue BayesClassifier::ClassifierAlreadyRunning => e
        assert_equal("The classifier is already running.", e.message)
        raise e
      end
    }
    
    assert_equal('jobkey', classifier.classifier_job.jobkey)
  end
    
  def test_start_background_process_raises_error
    MiddleMan.expects(:new_worker).raises
    assert_raise(StandardError) { BayesClassifier.find(1).start_background_classification }
  end
end
