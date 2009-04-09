# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class ConvertReadItemAndMessageReadingToReading < ActiveRecord::Migration
  def self.up
    execute "INSERT IGNORE INTO readings(user_id, readable_id, readable_type, created_at, updated_at) " <<
            "SELECT DISTINCT read_items.user_id, read_items.feed_item_id, 'FeedItem', read_items.created_at, read_items.created_at FROM read_items"
    execute "INSERT IGNORE INTO readings(user_id, readable_id, readable_type, created_at, updated_at) " <<
            "SELECT DISTINCT message_readings.user_id, message_readings.message_id, 'Message', message_readings.created_at, message_readings.updated_at FROM message_readings"
  end

  def self.down
    execute "INSERT IGNORE INTO read_items(user_id, feed_item_id, created_at, updated_at) " <<
            "SELECT DISTINCT readings.user_id, readings.readable_id, readings.created_at, readings.updated_at FROM readings WHERE readings.readable_type = 'FeedItem'"
    execute "INSERT IGNORE INTO message_readings(user_id, message_id, created_at, updated_at) " <<
            "SELECT DISTINCT readings.user_id, readings.readable_id, readings.created_at, readings.updated_at FROM readings WHERE readings.readable_type = 'Message'"
  end
end
