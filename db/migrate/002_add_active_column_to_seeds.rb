# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class AddActiveColumnToSeeds < ActiveRecord::Migration
  def self.up
    add_column "seeds", "active", :boolean, :default => true
  end

  def self.down
    remove_column "seeds", "active"
  end
end
