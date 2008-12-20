# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class AddIndexToTaggingsOnTagIdAndFeedItemId < ActiveRecord::Migration
  def self.up
    add_index :taggings, [:tag_id, :feed_item_id]
  end

  def self.down
    remove_index :taggings, [:tag_id, :feed_item_id]
  end
end
