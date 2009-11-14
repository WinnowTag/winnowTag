# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class IndexOnFeedItemsFeedId < ActiveRecord::Migration
  def self.up
    add_index :feed_items, :feed_id
    add_index :feed_items, :title
  end

  def self.down
    remove_index :feed_items, :feed_id
    remove_index :feed_items, :title
  end
end
