# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class RemoveUnreadItemsTable < ActiveRecord::Migration
  def self.up
    drop_table :unread_items
  end

  def self.down    
    create_table "unread_items", :force => true do |t|
      t.integer  "user_id"
      t.integer  "feed_item_id"
      t.datetime "created_on"
    end
  end
end
