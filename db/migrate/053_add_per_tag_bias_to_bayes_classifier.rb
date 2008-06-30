# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class AddPerTagBiasToBayesClassifier < ActiveRecord::Migration
  def self.up
    rename_column :bayes_classifiers, :bias, :default_bias
    rename_column :classifier_executions, :bias, :default_bias
    
    add_column :bayes_classifiers, :bias, :text
    add_column :classifier_executions, :bias, :text

    change_column_default(:bayes_classifiers, :default_bias, 1.0)
    change_column_default(:classifier_executions, :default_bias, 1.0)
  end

  def self.down
    remove_column :bayes_classifiers, :bias
    remove_column :classifier_executions, :bias

    rename_column :bayes_classifiers, :default_bias, :bias
    rename_column :classifier_executions, :default_bias, :bias

    change_column_default(:bayes_classifiers, :bias, 1.0)
    change_column_default(:classifier_executions, :bias, 1.0)
  end
end
