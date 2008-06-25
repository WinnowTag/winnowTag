# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class CreateClassifierExecutions < ActiveRecord::Migration
  def self.up
    create_table :classifier_executions, :force => true do |t|
      t.column :created_on, :datetime
      t.column :bias, :float
      t.column :min_prob_strength, :float
      t.column :max_discriminators, :integer
      t.column :unknown_word_strength, :float
      t.column :unknown_word_prob, :float
      t.column :min_train_count, :integer
      t.column :bayes_classifier_id, :integer
    end
    
    add_index :classifier_executions, :bayes_classifier_id
  end

  def self.down
    remove_index :classifier_executions, :bayes_classifier_id
    drop_table :classifier_executions
  end
end
