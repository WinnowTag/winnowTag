# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class TaggingMetadata < ActiveRecord::Migration
  def self.up
    add_column "taggings", "metadata_type", :string, :null => true
    add_column "taggings", "metadata_id", :integer, :null => true
  end

  def self.down
    remove_column "taggings", "metadata_type"
    remove_column "taggings", "metadata_id"
  end
end
