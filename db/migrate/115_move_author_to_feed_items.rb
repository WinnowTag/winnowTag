# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class MoveAuthorToFeedItems < ActiveRecord::Migration
  def self.up
    add_column :feed_items, :author, :string
    execute "update feed_items set author = (select author from feed_item_contents where feed_item_id = feed_items.id limit 1);"
    remove_column :feed_item_contents, :author
  end

  def self.down
    raise IrreversibleMigration
  end
end
