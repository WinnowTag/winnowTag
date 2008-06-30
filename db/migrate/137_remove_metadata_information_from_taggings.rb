# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class RemoveMetadataInformationFromTaggings < ActiveRecord::Migration
  def self.up
    remove_column :taggings, :metadata_id
    remove_column :taggings, :metadata_type
  end

  def self.down
    add_column :taggings, :metadata_id, :integer
    add_column :taggings, :metadata_type, :string
  end
end
