# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class IndexOnFeedItemTime < ActiveRecord::Migration
  def self.up
    add_index :feed_items, :time
  end

  def self.down
    remove_index :feed_items, :time
  end
end
