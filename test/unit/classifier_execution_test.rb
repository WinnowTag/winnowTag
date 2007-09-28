# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'

class ClassifierExecutionTest < Test::Unit::TestCase
  # Replace this with your real tests.
  def test_defaults_come_from_bayes_classifier
    classifier = BayesClassifier.create
    ce = classifier.create_classifier_execution
    assert_equal classifier.bias, ce.bias
    assert_equal classifier.default_bias, ce.default_bias
    assert_equal classifier.positive_cutoff, ce.positive_cutoff
    assert_equal classifier.insertion_cutoff, ce.insertion_cutoff
  end
  
  def test_set_attributes
    classifier = BayesClassifier.create(:default_bias => 1.1, :positive_cutoff => 0.8)
    ce = classifier.create_classifier_execution(:only => ['tag1', 'tag2'])
    
    ce.save!
    ce = ClassifierExecution.find(ce.id)
    assert_equal 1.1, ce.default_bias
    assert_equal classifier.bias, ce.bias
    assert_equal 1.1, ce.bias['tag']
    assert_equal 0.8, ce.positive_cutoff
    assert_equal ['tag1', 'tag2'], ce.only
  end
  
  def test_classification_options_sets_default_bias
    classifier = BayesClassifier.create(:default_bias => 1.1)
    ce = classifier.create_classifier_execution
    assert_equal(1.1, ce.classification_options[:bias].default)
  end
end
