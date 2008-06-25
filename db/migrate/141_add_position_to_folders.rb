# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class AddPositionToFolders < ActiveRecord::Migration
  def self.up
    add_column :folders, :position, :integer
  end

  def self.down
    remove_column :folders, :position
  end
end
