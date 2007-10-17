# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'

require 'bayes_classifier'
class BayesClassifierTest < Test::Unit::TestCase  
  fixtures :users, :tags, :feed_items, :bayes_classifiers, :classifier_datas
  
  def test_ignores_classification_of_non_classified_tags
    classifier = BayesClassifier.new.classifier
    
    mock_content = stub(:encoded_content => 'this is some content', :title => nil, :author => nil)
    mock_feed_item = FeedItem.new
    mock_feed_item.stubs(:content).returns(mock_content)
    
    # make sure that a probability cache is not built for 'seen'
    classifier.train('seen', mock_feed_item, '1')
    guesses = classifier.guess(mock_feed_item)
    assert_nil guesses['seen']
  end
  
  def test_training_passes_in_uid_of_feed_item
    mock_content = mock()
    mock_content.stubs(:encoded_content).returns('this is some content')
    mock_feed_item = FeedItem.new
    mock_feed_item.stubs(:content).returns(mock_content)
    mock_feed_item.stubs(:id).returns(37)
    
    tagging = Tagging.new
    tagging.stubs(:feed_item).returns(mock_feed_item)
    tagging.stubs(:tag).returns(Tag(users(:quentin), 'tag'))
    
    classifier = BayesClassifier.new
    classifier.classifier.expects(:train).with('tag', mock_feed_item, 'Winnow::FeedItem::37')
    classifier.train(tagging)
  end
  
  def test_classifier_contains_instance_of_bayes
    classifier = BayesClassifier.new
    assert classifier.classifier.is_a?(Bayes::Classifier)
  end
  
  def test_classifier_saves_bayes
    user = users(:quentin)
    classifier = BayesClassifier.new
    classifier.train(Tagging.new(:user => user, :feed_item => FeedItem.find(1), :tag => Tag(user, 'tag1')))
    assert_equal ['tag1'], classifier.classifier.pools_to_classify.map(&:name)
    classifier.save
    classifier = BayesClassifier.find(classifier.id)
    assert classifier.classifier_data
    assert_equal ['tag1'], classifier.classifier.pools_to_classify.map(&:name)
  end
  
  def test_classifier_acts_as_paranoid
    classifier = BayesClassifier.new
    classifier.user = User.find(1)
    assert classifier.save
    
    classifier_id = classifier.id
    assert_not_nil BayesClassifier.find(classifier_id)
    classifier.destroy
    assert_raise ActiveRecord::RecordNotFound do BayesClassifier.find(classifier_id) end
    deleted =  BayesClassifier.find_with_deleted(classifier_id)
    assert_not_nil deleted
        
    deleted.destroy!
    assert_raise ActiveRecord::RecordNotFound do BayesClassifier.find_with_deleted(classifier_id) end
  end
  
  
  def test_deleting_a_classifier_deletes_all_its_taggings
    # setup some data
    u1 = User.find(1)
    fi1 = FeedItem.find(1)
    fi2 = FeedItem.find(2)
    peerworks = Tag(u1, 'peerworks')
    
    classifier = BayesClassifier.new
    classifier.user = u1
    assert classifier.save
    
    tagging1 = Tagging.create(:user => u1, :feed_item => fi1, :tag => peerworks, :classifier_tagging => true)
    tagging2 = Tagging.create(:user => u1, :feed_item => fi2, :tag => peerworks, :classifier_tagging => true)
    
    assert_equal 2, classifier.user.taggings.size
    classifier.destroy
    
    assert_raise ActiveRecord::RecordNotFound do Tagging.find(tagging1.id) end 
    assert_raise ActiveRecord::RecordNotFound do Tagging.find(tagging1.id) end 
  end
  
  def test_classify_creates_taggings
    assert_equal 0, Tagging.count
    user = users(:quentin)
    classifier = user.classifier
    fi = FeedItem.find(1)
    Tagging.create(:user => user, :feed_item => fi, :tag => Tag(users(:quentin), 'tag1'))
    classifier.classifier.expects(:guess).returns({'tag1' => 0.95})
    classifier.classifier.stubs(:pools).returns({'tag1' => stub(:train_count => 10)})
    
    classifier.classify(fi)
    
    assert_equal 2, Tagging.count
    tagging = Tagging.find(:all).last
    assert_equal user, tagging.user
    assert_equal fi, tagging.feed_item
    assert_equal Tag(users(:quentin), 'tag1'), tagging.tag
    assert_equal 0.95, tagging.strength
    assert tagging.classifier_tagging?
  end
  
  def test_classify_doesnt_create_taggings_when_prob_less_than_cutoff
    assert_equal 0, Tagging.count
    user = users(:quentin)
    classifier = user.classifier
    classifier.insertion_cutoff = 0.9
    fi = FeedItem.find(1)
    Tagging.create(:user => user, :feed_item => fi, :tag => Tag(users(:quentin), 'tag1'))
    classifier.classifier.expects(:guess).returns({'tag1' => 0.6})
    classifier.classifier.stubs(:pools).returns({'tag1' => stub(:train_count => 10)})
    
    classifier.classify(fi)
    
    assert_equal 1, Tagging.count
  end

  def test_classify_new_only_classifies_items_added_since_the_last_execution
    classifier = BayesClassifier.find(1)
    classifier.user.taggings.create(:tag => Tag(users(:quentin), 'tag'), :feed_item => FeedItem.find(1))
    classifier.expects(:classify).times(3)
    classifier.last_executed = Time.now.yesterday
    classifier.classify_new_items
  end
  
  def test_classify_new_does_nothing_with_no_new_items
    classifier = BayesClassifier.find(1)
    classifier.user.taggings.create(:tag => Tag(users(:quentin), 'tag'), :feed_item => FeedItem.find(1))
    classifier.last_executed = Time.now.tomorrow.tomorrow
    classifier.expects(:classify).never
    classifier.classify_new_items
  end
  
  def test_classify_new_bails_out_when_there_are_no_tags
    classifier = BayesClassifier.find(1)
    classifier.last_executed = Time.now.tomorrow
    FeedItem.expects(:find).never
    classifier.classify_new_items
  end
  
  def test_classify_all_uses_iteration
    fi1 = FeedItem.find(1)
    fi2 = FeedItem.find(2)
    fi3 = FeedItem.find(3)
    fi4 = FeedItem.find(4)
    
    classifier = BayesClassifier.find(1)
    FeedItem.expects(:each_with_index).with{|o| o[:column] == :position}.multiple_yields([fi1, 1],[fi2, 2],[fi3, 3], [fi4, 4])
    classifier.expects(:classify).times(4)
    classifier.classify_all()
  end
    
  def test_classify_all_yeilds_global_index
    fi1 = FeedItem.find(1)
    fi2 = FeedItem.find(2)
    fi3 = FeedItem.find(3)
    fi4 = FeedItem.find(4)
    
    FeedItem.expects(:each_with_index).multiple_yields([fi1, 1],[fi2, 2],[fi3, 3], [fi4, 4])
    
    classifier = BayesClassifier.find(1)
    indexes = []
    classifier.classify_all do |item, index|
      indexes << index
    end
    assert_equal [1,2,3,4], indexes
  end
    
  def test_classify_uses_execution_options_when_none_are_provided
    fi = FeedItem
    c = BayesClassifier.find(:first)
    c.default_bias = 1.2
    c.save
    c.classifier.expects(:guess).with do |item, options|
      options[:default_bias] == 1.2 and item == fi
    end
    c.classify(fi)
  end
  
  def test_classify_uses_nil_options_when_nil_is_specified
    fi = FeedItem
    c = BayesClassifier.find(:first)
    c.classifier.expects(:guess).with(fi, nil)
    c.classify(fi, c.create_classifier_execution, nil)
  end
  
  def test_classify_uses_insertion_cutoff_parameter
    assert_equal 0, Tagging.count
    user = users(:quentin)
    classifier = user.classifier
    classifier.insertion_cutoff = 0.8
    classifier.save
    fi = FeedItem.find(1)
    Tagging.create(:user => user, :feed_item => fi, :tag => Tag(users(:quentin), 'tag1'))
    classifier.classifier.expects(:guess).returns({'tag1' => 0.8})
    classifier.classifier.stubs(:pools).returns({'tag1' => stub(:train_count => 10)})

    classifier.classify(fi)
    
    assert_equal 2, Tagging.count
    tagging = Tagging.find(:all).last
    assert_equal user, tagging.user
    assert_equal fi, tagging.feed_item
    assert_equal Tag(users(:quentin), 'tag1'), tagging.tag
    assert_equal 0.8, tagging.strength
    assert tagging.classifier_tagging?
  end
  
  def test_classify_adds_execution_data_to_tagging
    user = users(:quentin)
    fi = FeedItem.find(1)
    Tagging.create(:user => user, :feed_item => fi, :tag => Tag(users(:quentin), 'tag1'))
    classifier = user.classifier
    ce = classifier.create_classifier_execution
    classifier.classifier.expects(:guess).returns({'tag1' => 0.95})
    classifier.classifier.stubs(:pools).returns({'tag1' => stub(:train_count => 10)})
    classifier.classify(fi, ce)
    
    assert_equal 1, classifier.user.classifier_taggings.size
    ce_db = classifier.user.classifier_taggings.first.metadata
    assert ce_db.is_a?(ClassifierExecution)
    assert_equal ce, ce_db
  end
  
  def test_train_random_background
    fi = FeedItem.find(1)
    FeedItem.expects(:find_random_items_with_tokens).with(1).returns([fi])
    classifier = users(:quentin).classifier
    classifier.random_background_size = 1 
    classifier.classifier.expects(:train).with(BayesClassifier::RANDOM_BACKGROUND, fi, fi.uid)
    classifier.train_random_background
  end
  
  def test_train_random_background_size
    fi = FeedItem.find(1)
    FeedItem.expects(:find_random_items_with_tokens).with(1).returns([fi])
    classifier = users(:quentin).classifier
    classifier.random_background_size = 1  
    classifier.train_random_background
    assert_equal 1, classifier.classifier.pools[BayesClassifier::RANDOM_BACKGROUND].train_count
  end
  
  def test_train_random_background_twice
    fi = FeedItem.find(1)
    FeedItem.expects(:find_random_items_with_tokens).with(1).returns([fi]).times(2)
    classifier = users(:quentin).classifier
    classifier.random_background_size = 1 
    classifier.train_random_background
    assert_equal 1, classifier.classifier.pools[BayesClassifier::RANDOM_BACKGROUND].train_count
    classifier.train_random_background
    assert_equal 1, classifier.classifier.pools[BayesClassifier::RANDOM_BACKGROUND].train_count
  end
  
  def test_classification_options
    classifier = BayesClassifier.create
    opts = classifier.classification_options
    assert_include :bias, opts.keys
    assert_include :random_background_size, opts.keys
    assert_include :positive_cutoff, opts.keys
    assert_include :insertion_cutoff, opts.keys
  end
  
  def test_classification_options_sets_default_bias
    classifier = BayesClassifier.create
    classifier.bias = {'tag' => 1.2}
    opts = classifier.classification_options
    assert_equal classifier.default_bias, opts[:bias].default    
  end
  
  def test_default_per_tag_bias
    classifier = BayesClassifier.create
    assert_equal(1.0, classifier.default_bias)
    assert_equal(1.0, classifier.bias.default)
    classifier.default_bias = 1.5
    assert_equal(1.5, classifier.default_bias)
    assert_equal(1.5, classifier.bias.default)
  end
  
  def test_per_tag_bias_persistance
    classifier = BayesClassifier.create    
    classifier.default_bias = 1.5
    classifier.bias['tag1'] = 1.2
    classifier.save
    
    classifier.reload
    assert_equal(1.5, classifier.bias.default)
    assert_equal(1.2, classifier.bias['tag1'])
    assert_equal(1.5, classifier.bias['tag2'])
  end
  
  def test_setting_bias_hash_updates_existing
    classifier = BayesClassifier.create
    classifier.bias = {'tag1' => 1.1, 'tag2' => 1.2}
    
    assert_equal(1.1, classifier.bias['tag1'])
    assert_equal(1.2, classifier.bias['tag2'])
    
    classifier.bias = {'tag1' => 1.3, 'tag3' => 0.9}
    
    assert_equal(1.3, classifier.bias['tag1'])
    assert_equal(1.2, classifier.bias['tag2'])
    assert_equal(0.9, classifier.bias['tag3'])
  end
  
  def test_setting_bias_value_to_default
    classifier = BayesClassifier.create
    classifier.bias = {'tag1' => 1.1, 'tag2' => 1.2}
    
    assert_equal(1.1, classifier.bias['tag1'])
    assert_equal(1.2, classifier.bias['tag2'])
    
    classifier.bias = {'tag1' => 'default'}
    assert_equal(classifier.default_bias, classifier.bias['tag1'])
    assert_equal(1.2, classifier.bias['tag2'])
  end
  
  def test_update_training_with_no_taggings
    classifier = BayesClassifier.find(1)
    classifier.expects(:train).never
    classifier.update_training
  end
  
  def test_update_training_with_new_tagging
    tagging = Tagging.create(:user => users(:quentin), :tag => Tag(users(:quentin), 'tag'), :feed_item => FeedItem.find(1))
    classifier = BayesClassifier.find(1)
    classifier.expects(:train).with(tagging)
    classifier.update_training
  end
  
  def test_update_training_with_no_updates
    tagging = Tagging.create(:user => users(:quentin), :tag => Tag(users(:quentin), 'tag'), :feed_item => FeedItem.find(1))
    classifier = BayesClassifier.find(1)
    classifier.expects(:random_background_uptodate?).returns(true).times(2)
    classifier.expects(:train).with(tagging).times(1)
    classifier.update_training
    classifier.update_training
  end
  
  def test_update_training_with_a_new_tagging
    tagging1 = Tagging.create(:user => users(:quentin), :tag => Tag(users(:quentin), 'tag'), :feed_item => FeedItem.find(1))
    classifier = BayesClassifier.find(1)
    classifier.expects(:random_background_uptodate?).returns(true).times(2)
    classifier.expects(:train).with(tagging1).times(1)
    classifier.update_training
    
    # wait a second since timestamps only work on seconds
    sleep(1)
    
    tagging2 = Tagging.create(:user => users(:quentin), :tag => Tag(users(:quentin), 'tag'), :feed_item => FeedItem.find(2))
    classifier.expects(:train).with(tagging2).times(1)
    classifier.update_training  
  end
  
  def test_update_training_with_a_deleted_tagging
    tagging1 = Tagging.create(:user => users(:quentin), :tag => Tag(users(:quentin), 'tag'), :feed_item => FeedItem.find(1))
    classifier = BayesClassifier.find(1)
    classifier.expects(:retrain).never
    classifier.expects(:random_background_uptodate?).returns(true).times(2)
    classifier.expects(:train).with(tagging1).times(1)
    classifier.update_training
    sleep(1)
    tagging1.destroy
    classifier.expects(:untrain).with(classifier.user.deleted_taggings.first).times(1)
    classifier.update_training
  end
  
  def test_update_training_ignores_taggings_created_and_destroyed_between_trainings
    FeedItem.stubs(:find_random_items_with_tokens).returns([])
    classifier = BayesClassifier.find(1)
    classifier.expects(:train).never
    classifier.expects(:untrain).never
    classifier.update_training
    sleep(1)
    tagging1 = Tagging.create(:user => users(:quentin), :tag => Tag(users(:quentin), 'tag'), :feed_item => FeedItem.find(1))
    tagging1.destroy
    classifier.update_training
  end
  
  def test_update_training_after_clearing_training_data
    tagging = Tagging.create(:user => users(:quentin), :tag => Tag(users(:quentin), 'tag'), :feed_item => FeedItem.find(1))
    classifier = BayesClassifier.find(1)
    classifier.expects(:random_background_uptodate?).returns(true).times(2)
    classifier.expects(:train).with(tagging).times(2)
    classifier.update_training
    classifier.clear_training_data
    classifier.update_training
  end
  
  def test_random_background_uptodate
    classifier = BayesClassifier.find(1)
    assert !classifier.random_background_uptodate?
  end
  
  def test_random_background_uptodate_should_be_true_after_trained
    FeedItem.expects(:find_random_items_with_tokens).with(2).returns([FeedItem.find(1), FeedItem.find(2)])
    classifier = BayesClassifier.find(1)
    classifier.random_background_size = 2
    classifier.train_random_background
    assert classifier.random_background_uptodate?
  end
  
  def test_random_background_uptodate_should_be_false_when_size_setting_changes
    FeedItem.expects(:find_random_items_with_tokens).with(2).returns([FeedItem.find(1), FeedItem.find(2)])
    classifier = BayesClassifier.find(1)
    classifier.random_background_size = 2
    classifier.train_random_background
    assert classifier.random_background_uptodate?
    classifier.random_background_size = 3
    assert !classifier.random_background_uptodate?
  end
  
  def test_regression_test_fails_with_high_error
    classifier = BayesClassifier.find(1)
    classifier.user.taggings.create(:feed_item => FeedItem.find(1), :tag => Tag(users(:quentin), 'tag'), :strength => 0, :classifier_tagging => true)
    classifier.expects(:guess).with{|fi, options| fi == FeedItem.find(1)}.returns('tag' => 1)
    assert_raise(BayesClassifier::RegressionTestFailure) { classifier.regression_test }
  end
  
  def test_regression_test_passes_with_no_error
    classifier = BayesClassifier.find(1)
    classifier.user.taggings.create(:feed_item => FeedItem.find(1), :tag => Tag(users(:quentin), 'tag'), :strength => 1, :classifier_tagging => true)
    classifier.expects(:guess).with{|fi, options| fi == FeedItem.find(1)}.returns('tag' => 1)
    assert_nothing_raised(BayesClassifier::RegressionTestFailure) { classifier.regression_test }
  end
  
  def test_regression_test_passes_within_error_limit
    classifier = BayesClassifier.find(1)
    classifier.user.taggings.create(:feed_item => FeedItem.find(1), :tag => Tag(users(:quentin), 'tag'), :strength => 1, :classifier_tagging => true)
    classifier.expects(:guess).with{|fi, options| fi == FeedItem.find(1)}.returns('tag' => 0.9)
    assert_nothing_raised(BayesClassifier::RegressionTestFailure) { classifier.regression_test(0.1) }
  end
  
  def test_regression_test_fails_outside_error_limit
    classifier = BayesClassifier.find(1)
    classifier.user.taggings.create(:feed_item => FeedItem.find(1), :tag => Tag(users(:quentin), 'tag'), :strength => 1, :classifier_tagging => true)
    classifier.expects(:guess).with{|fi, options| fi == FeedItem.find(1)}.returns('tag' => 0.89)
    assert_raise(BayesClassifier::RegressionTestFailure) { classifier.regression_test(0.1) }
  end
  
  def test_delete_orphaned_taggings_should_delete_an_orphaned_tagging
    classifier = BayesClassifier.find(1)
    tagging = classifier.user.taggings.create(:feed_item => FeedItem.find(1), :tag => Tag(users(:quentin), 'tag'), :classifier_tagging => true)
    FeedItem.delete(1)
    BayesClassifier.delete_orphaned_taggings
    assert_raise(ActiveRecord::RecordNotFound) { Tagging.find(tagging.id) }
  end
  
  def test_delete_orphan_taggings_should_leave_non_orphan_tagging
    classifier = BayesClassifier.find(1)
    tagging = classifier.user.taggings.create(:feed_item => FeedItem.find(1), :tag => Tag(users(:quentin), 'tag'), :classifier_tagging => true)
    BayesClassifier.delete_orphaned_taggings
    assert_nothing_raised(ActiveRecord::RecordNotFound) { Tagging.find(tagging.id) }
  end
  
  def test_delete_orphan_taggings_should_leave_non_orphaned_user_taggings
    user = users(:quentin)
    tagging = user.taggings.create(:feed_item => FeedItem.find(1), :tag => Tag(users(:quentin), 'tag'))
    BayesClassifier.delete_orphaned_taggings
    assert_nothing_raised(ActiveRecord::RecordNotFound) { Tagging.find(tagging.id) }
  end

  def test_delete_orphan_taggings_should_leave_orphaned_user_taggings
    user = users(:quentin)
    tagging = user.taggings.create(:feed_item => FeedItem.find(1), :tag => Tag(users(:quentin), 'tag'))
    FeedItem.delete(1)
    BayesClassifier.delete_orphaned_taggings
    assert_nothing_raised(ActiveRecord::RecordNotFound) { Tagging.find(tagging.id) }
  end
  
  def test_changed_tags_should_return_empty_array_when_no_tags_are_changed
    user = users(:quentin)
    user.classifier.last_executed = Time.now.utc
    assert_equal([], user.classifier.changed_tags)
  end
  
  def test_changed_tags_should_return_tag_altered_since_the_last_classification
    user = users(:quentin)
    user.classifier.last_executed = Time.now.ago(5.minutes).utc
    user.taggings.create(:feed_item => FeedItem.find(1), :tag => Tag(users(:quentin), 'tag1'))
    assert_equal([Tag(users(:quentin), 'tag1')], user.classifier.changed_tags)
  end
  
  def test_changed_tags_should_return_tag_negatively_altered_since_the_last_classification
    user = users(:quentin)
    user.classifier.last_executed = Time.now.ago(5.minutes).utc
    user.taggings.create(:feed_item => FeedItem.find(1), :tag => Tag(users(:quentin), 'tag1'), :strength => 0)
    assert_equal([Tag(users(:quentin), 'tag1')], user.classifier.changed_tags)
  end
  
  def test_changed_tags_should_return_multiple_altered_tags_since_the_last_classification
    user = users(:quentin)
    user.classifier.last_executed = Time.now.ago(5.minutes).utc
    user.taggings.create(:feed_item => FeedItem.find(1), :tag => Tag(users(:quentin), 'tag1'))
    user.taggings.create(:feed_item => FeedItem.find(1), :tag => Tag(users(:quentin), 'tag2'))
    assert_equal([Tag(users(:quentin), 'tag1'), Tag(users(:quentin), 'tag2')], user.classifier.changed_tags)
  end
  
  def test_changed_tags_should_return_distinct_altered_tags_since_the_last_classification
    user = users(:quentin)
    user.classifier.last_executed = Time.now.ago(5.minutes).utc
    user.taggings.create(:feed_item => FeedItem.find(1), :tag => Tag(users(:quentin), 'tag1'))
    user.taggings.create(:feed_item => FeedItem.find(2), :tag => Tag(users(:quentin), 'tag1'))
    assert_equal([Tag(users(:quentin), 'tag1')], user.classifier.changed_tags)
  end
  
  def test_changed_tags_should_return_tag_removed_since_last_classification
    user = users(:quentin)
    user.classifier.last_executed = Time.now.ago(5.minutes).utc
    user.taggings.create(:feed_item => FeedItem.find(1), :tag => Tag(users(:quentin), 'tag1'),
                         :created_on => Time.now.ago(10.minutes).utc).destroy
    assert_equal([Tag(users(:quentin), 'tag1')], user.classifier.changed_tags)
  end
  
  def test_changed_tags_should_return_all_tags_for_new_classifier
    user = users(:quentin)
    user.classifier.last_executed = nil
    user.taggings.create(:feed_item => FeedItem.find(1), :tag => Tag(users(:quentin), 'tag1'))
    user.taggings.create(:feed_item => FeedItem.find(1), :tag => Tag(users(:quentin), 'tag2'))
    assert_equal([Tag(users(:quentin), 'tag1'), Tag(users(:quentin), 'tag2')], user.classifier.changed_tags)    
  end
  
  def test_clear_existing_taggings_only_removes_classifier_taggings
    user = users(:quentin)
    t = user.taggings.create(:feed_item => FeedItem.find(1), :tag => Tag(user, 'tag1'))
    user.taggings.create(:feed_item => FeedItem.find(1), :tag => Tag(user, 'tag1'), :classifier_tagging => true)
    assert_difference(user.taggings, :size, -1) do
      user.classifier.clear_existing_taggings('tag1')
    end
    
    assert_nothing_raised(ActiveRecord::RecordNotFound) { Tagging.find(t.id) }
  end
end
