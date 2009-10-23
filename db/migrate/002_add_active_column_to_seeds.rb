# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class AddActiveColumnToSeeds < ActiveRecord::Migration
  def self.up
    add_column "seeds", "active", :boolean, :default => true
  end

  def self.down
    remove_column "seeds", "active"
  end
end
