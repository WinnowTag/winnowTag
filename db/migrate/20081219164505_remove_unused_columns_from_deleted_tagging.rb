# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class RemoveUnusedColumnsFromDeletedTagging < ActiveRecord::Migration
  def self.up
    remove_column :deleted_taggings, :metadata_type
    remove_column :deleted_taggings, :metadata_id
  end

  def self.down
    add_column :deleted_taggings, :metadata_type, :string
    add_column :deleted_taggings, :metadata_id, :integer
  end
end
