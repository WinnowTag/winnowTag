# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class RemoveSettings < ActiveRecord::Migration
  def self.up
    drop_table :settings
  end

  def self.down
    create_table :settings do |t|
      t.string :name
      t.text :value

      t.timestamps
    end
  end
end
