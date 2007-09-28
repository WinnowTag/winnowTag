# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
class IndexOnFeedItemUid < ActiveRecord::Migration
  def self.up
    add_index :feed_items, :unique_id
  end

  def self.down
    remove_index :feed_items, :unique_id
  end
end
