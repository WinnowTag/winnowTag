# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class ActsAsReadableMigration < ActiveRecord::Migration
  def self.up
    create_table :readings do |t|
      t.string :readable_type
      t.integer :readable_id
      t.integer :user_id
      t.timestamps
    end
    add_index :readings, [:user_id, :readable_id, :readable_type], :unique => true
  end
  
  def self.down
    drop_table :readings
  end
end
