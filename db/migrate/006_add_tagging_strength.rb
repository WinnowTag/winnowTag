# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class AddTaggingStrength < ActiveRecord::Migration
  def self.up
    add_column "taggings", "strength", :float, :default => 1.0
  end

  def self.down
    remove_column "taggings", "strength"
  end
end
