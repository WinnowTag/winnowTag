# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class CreateClassifierJobs < ActiveRecord::Migration
  def self.up
    create_table :classifier_jobs do |t|
      t.column :bayes_classifier_id, :integer
      t.column :jobkey, :string
      t.column :progress, :integer, :default => 0
      t.column :progress_title, :string, :default => "Starting Classifier"
      t.column :progress_message, :text
      t.column :error_message, :text
      t.column :complete, :boolean, :default => false
      t.column :failed, :boolean, :default => false
      t.column :created_on, :datetime
      t.column :updated_on, :datetime
    end
    
    remove_column :bayes_classifiers, :jobkey
  end

  def self.down
    add_column :bayes_classifiers, :jobkey, :string
    drop_table :classifier_jobs
  end
end
