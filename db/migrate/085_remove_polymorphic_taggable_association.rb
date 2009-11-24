# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class RemovePolymorphicTaggableAssociation < ActiveRecord::Migration
  def self.up
    rename_column :taggings, :taggable_id, :feed_item_id
    remove_column :taggings, :taggable_type
  end

  def self.down
    rename_column :taggings, :feed_item_id, :taggable_id
    add_column :taggings, :taggable_type, :string
    execute "update taggings set taggable_type = 'FeedItem';"
  end
end
