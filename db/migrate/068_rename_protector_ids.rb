# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class RenameProtectorIds < ActiveRecord::Migration
  def self.up
    rename_table :protector_ids, :protectors
  end

  def self.down
    rename_table :protectors, :protector_ids
  end
end
