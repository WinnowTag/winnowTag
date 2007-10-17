# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

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
