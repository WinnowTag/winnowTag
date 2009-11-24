# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class ConvertUnreadItemsToReadItems < ActiveRecord::Migration
  class ReadItem < ActiveRecord::Base; end
  
  def self.up
    ReadItem.transaction do
      execute <<-EOSQL
        INSERT INTO read_items (user_id, feed_item_id, created_at) 
          SELECT users.id AS user_id, feed_items.id AS feed_item_id, UTC_TIMESTAMP() FROM users, feed_items 
          WHERE feed_items.id NOT IN (SELECT feed_item_id FROM unread_items WHERE user_id = users.id)
      EOSQL
    end
  end

  def self.down
  end
end
