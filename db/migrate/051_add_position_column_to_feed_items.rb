# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class AddPositionColumnToFeedItems < ActiveRecord::Migration
  def self.up
    add_column :feed_items, :position, :integer
    add_index :feed_items, [:position], :unique => true
    FeedItem.update_positions if FeedItem.respond_to? :update_positions
  end

  def self.down
    remove_column :feed_items, :position
    remove_index :feed_items, :column => :position
  end
end
