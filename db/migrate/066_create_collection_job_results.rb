# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class CreateCollectionJobResults < ActiveRecord::Migration
  def self.up
    create_table :collection_job_results do |t|
      t.column :feed_id, :integer
      t.column :user_id, :integer
      t.column :message, :text
      t.column :failed, :boolean, :default => false
      t.column :user_notified, :boolean, :default => false
      t.column :created_on, :datetime
    end
  end

  def self.down
    drop_table :collection_job_results
  end
end
