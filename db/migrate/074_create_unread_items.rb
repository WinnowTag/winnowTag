# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class CreateUnreadItems < ActiveRecord::Migration
  def self.up
    create_table :unread_items do |t|
      t.column :user_id, :integer
      t.column :feed_item_id, :integer
      t.column :created_on, :datetime
    end
    
    add_index :unread_items, [:user_id, :feed_item_id], :unique => true
  end

  def self.down
    drop_table :unread_items
  end
end
