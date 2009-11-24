# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.


class AddUriColumnToFeedItems < ActiveRecord::Migration
  def self.up
    add_column :feed_items, :uri, :string
    add_index :feed_items, [:uri], :unique => true
  end

  def self.down
    remove_column :feed_items, :uri
  end
end
