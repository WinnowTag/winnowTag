# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class RemoveProtectors < ActiveRecord::Migration
  def self.up
    drop_table :protectors
  end

  def self.down
    create_table :protectors do |t|
      t.integer :protector_id
      t.datetime :created_on
    end
  end
end
