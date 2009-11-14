# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class DropReadItemsAndMessageReadings < ActiveRecord::Migration
  def self.up
    drop_table :message_readings
    drop_table :read_items
  end

  def self.down
    create_table "read_items", :force => true do |t|
      t.integer  "user_id"
      t.integer  "feed_item_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    
    create_table "message_readings", :force => true do |t|
      t.integer  "message_id"
      t.integer  "user_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
