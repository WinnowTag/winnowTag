# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class DropRedundantIndexes < ActiveRecord::Migration
  def self.up
    remove_index(:feed_item_contents, :feed_item_id) rescue nil
    execute("drop index feed_item_contents_feed_item_id_index on feed_item_contents;") rescue nil
    execute "alter table feed_item_contents add foreign key (feed_item_id) references feed_items(id) on delete cascade;"
  end

  def self.down
    raise IrreversibleMigration
  end
end
