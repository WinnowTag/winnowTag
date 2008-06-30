# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class AddForeignKeyFromTaggingsToFeedItems < ActiveRecord::Migration
  def self.up
    execute "delete from taggings where feed_item_id not in (select id from feed_items);"
    execute "alter table taggings add foreign key (feed_item_id) references feed_items(id) on delete cascade;"
  end

  def self.down
  end
end
