# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class AddClassifierOptionsToBayesClassifier < ActiveRecord::Migration
  def self.up
    add_column :bayes_classifiers, :bias, :float, :default => 1.0
    add_column :bayes_classifiers, :min_prob_strength, :float, :default => 0.1
    add_column :bayes_classifiers, :max_discriminators, :integer, :default => 150
    add_column :bayes_classifiers, :unknown_word_strength, :float, :default => 0.45
    add_column :bayes_classifiers, :unknown_word_prob, :float, :default => 0.5
    add_column :bayes_classifiers, :min_train_count, :integer, :default => 0
    add_column :bayes_classifiers, :classification_cutoff, :float, :default => 0.9
    add_column :bayes_classifiers, :incremental_training_cutoff, :float, :default => 0.8
    add_column :bayes_classifiers, :incremental_training_limit, :integer, :default => 1000
    add_column :bayes_classifiers, :random_background_size, :integer, :default => 400
    add_column :bayes_classifiers, :background_weights, :text
    add_column :bayes_classifiers, :foreground_weights, :text
    
    add_column :classifier_executions, :background_weights, :text
    add_column :classifier_executions, :foreground_weights, :text
    add_column :classifier_executions, :random_background_size, :integer
    rename_column :classifier_executions, :cutoff, :classification_cutoff
    add_column :classifier_executions, :incremental_training_cutoff, :float
    add_column :classifier_executions, :classification_mode, :string, :default => 'classification'
  end

  def self.down
    remove_column :bayes_classifiers, :bias
    remove_column :bayes_classifiers, :min_prob_strength
    remove_column :bayes_classifiers, :max_discriminators
    remove_column :bayes_classifiers, :unknown_word_strength
    remove_column :bayes_classifiers, :unknown_word_prob
    remove_column :bayes_classifiers, :min_train_count
    remove_column :bayes_classifiers, :classification_cutoff
    remove_column :bayes_classifiers, :incremental_training_cutoff
    remove_column :bayes_classifiers, :random_background_size
    remove_column :bayes_classifiers, :background_weights
    remove_column :bayes_classifiers, :foreground_weights
    
    remove_column :classifier_executions, :background_weights
    remove_column :classifier_executions, :foreground_weights
    remove_column :classifier_executions, :random_background_size
    rename_column :classifier_executions, :classification_cutoff, :cutoff
    remove_column :classifier_executions, :incremental_training_cutoff
    remove_column :classifier_executions, :classification_mode
    remove_column :bayes_classifiers, :incremental_training_limit
  end
end
