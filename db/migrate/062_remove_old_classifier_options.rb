# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class RemoveOldClassifierOptions < ActiveRecord::Migration
  def self.up
    remove_column :bayes_classifiers, :min_token_count
    remove_column :bayes_classifiers, :min_train_count
    remove_column :bayes_classifiers, :min_prob_strength
    remove_column :bayes_classifiers, :unknown_word_strength
    remove_column :bayes_classifiers, :unknown_word_prob
    remove_column :bayes_classifiers, :max_discriminators
    remove_column :bayes_classifiers, :foreground_weights
    remove_column :bayes_classifiers, :background_weights
    
    remove_column :classifier_executions, :min_token_count
    remove_column :classifier_executions, :min_train_count
    remove_column :classifier_executions, :min_prob_strength
    remove_column :classifier_executions, :unknown_word_strength
    remove_column :classifier_executions, :unknown_word_prob
    remove_column :classifier_executions, :max_discriminators
    remove_column :classifier_executions, :foreground_weights
    remove_column :classifier_executions, :background_weights
  end

  def self.down
    add_column :bayes_classifiers, :min_token_count, :integer, :default => 50
    add_column :bayes_classifiers, :min_train_count, :integer, :default => 0
    add_column :bayes_classifiers, :min_prob_strength, :float, :default => 0.1
    add_column :bayes_classifiers, :unknown_word_prob, :float, :default => 0.5
    add_column :bayes_classifiers, :unknown_word_strength, :float, :default => 0.45
    add_column :bayes_classifiers, :max_discriminators, :integer, :default => 150  
    add_column :bayes_classifiers, :foreground_weights, :text
    add_column :bayes_classifiers, :background_weights, :text
    
    add_column :classifier_executions, :min_token_count, :integer, :default => 50
    add_column :classifier_executions, :min_train_count, :integer, :default => 0
    add_column :classifier_executions, :min_prob_strength, :float, :default => 0.1
    add_column :classifier_executions, :unknown_word_prob, :float, :default => 0.5
    add_column :classifier_executions, :unknown_word_strength, :float, :default => 0.45
    add_column :classifier_executions, :max_discriminators, :integer, :default => 150  
    add_column :classifier_executions, :foreground_weights, :text
    add_column :classifier_executions, :background_weights, :text
  end
end
