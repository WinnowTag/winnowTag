# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class CreateReadItems < ActiveRecord::Migration
  def self.up
    create_table :read_items do |t|
      t.integer :user_id
      t.integer :feed_item_id

      t.timestamps
    end
    
    add_index :read_items, [:user_id, :feed_item_id], :unique => true
  end

  def self.down
    drop_table :read_items
  end
end
