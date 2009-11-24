# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class DropCollectionJobResults < ActiveRecord::Migration
  def self.up
    drop_table :collection_job_results
  end

  def self.down
    create_table :collection_job_results do |t|
      t.integer :feed_id, :user_id
      t.text :message
      t.boolean :failed, :user_notified, :default => false
      t.datetime :created_on
    end
  end
end
