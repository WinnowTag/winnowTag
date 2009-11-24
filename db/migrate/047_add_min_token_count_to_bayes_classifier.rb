# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class AddMinTokenCountToBayesClassifier < ActiveRecord::Migration
  def self.up
    add_column :bayes_classifiers, :min_token_count, :integer, :default => 20
    add_column :classifier_executions, :min_token_count, :integer, :default => 20
  end

  def self.down
    remove_column :bayes_classifiers, :min_token_count
    remove_column :classifier_executions, :min_token_count
  end
end
