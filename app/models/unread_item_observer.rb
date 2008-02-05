# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class UnreadItemObserver < ActiveRecord::Observer
  observe :feed_item
  
  def after_create(item)
    UnreadItem.connection.execute("INSERT INTO unread_items " + 
                                   "(feed_item_id, user_id, created_on) " +
                                   "SELECT #{item.id}, id, UTC_TIMESTAMP() from users")
  end
end