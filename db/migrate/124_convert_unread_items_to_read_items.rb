# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class ConvertUnreadItemsToReadItems < ActiveRecord::Migration
  def self.up
    ReadItem.transaction do
      execute "insert into read_items (user_id, feed_item_id, created_at) " + 
                "(select users.id as user_id, feed_items.id as feed_item_id, UTC_TIMESTAMP() " +
                  "from users, feed_items " +
                  "where feed_items.id not in " +
                    "(select feed_item_id from unread_items where user_id = users.id)" +
                ")"
    end
  end

  def self.down
  end
end
