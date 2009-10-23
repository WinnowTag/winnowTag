# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class RemoveIncrementalTrainingSettings < ActiveRecord::Migration
  def self.up
    rename_column :bayes_classifiers, :classification_cutoff, :positive_cutoff
    rename_column :bayes_classifiers, :incremental_training_cutoff, :insertion_cutoff
    remove_column :bayes_classifiers, :incremental_training_limit
    add_column :bayes_classifiers, :borderline_threshold, :float, :default => 0.02
    
    rename_column :classifier_executions, :classification_cutoff, :positive_cutoff
    rename_column :classifier_executions, :incremental_training_cutoff, :insertion_cutoff
    remove_column :classifier_executions, :classification_mode
    
    change_column_default(:bayes_classifiers, :positive_cutoff, 0.9)
    change_column_default(:bayes_classifiers, :insertion_cutoff, 0.8)
  end

  def self.down
    rename_column :bayes_classifiers, :positive_cutoff, :classification_cutoff
    rename_column :bayes_classifiers, :insertion_cutoff, :incremental_training_cutoff
    add_column :bayes_classifiers, :incremental_training_limit, :integer, :default => 1000
    remove_column :bayes_classifiers, :borderline_threshold
    
    rename_column :classifier_executions, :positive_cutoff, :classification_cutoff
    rename_column :classifier_executions, :insertion_cutoff, :incremental_training_cutoff
    add_column :classifier_executions, :classification_mode, :string, :default => 'classification'
  end
end
