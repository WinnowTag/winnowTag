# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class IndexOnFeedItemTime < ActiveRecord::Migration
  def self.up
    add_index :feed_items, :time
  end

  def self.down
    remove_index :feed_items, :time
  end
end
