# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class CreateProtectorIds < ActiveRecord::Migration
  def self.up
    create_table :protector_ids do |t|
      t.column :protector_id, :integer
      t.column :created_on, :datetime
    end
  end

  def self.down
    drop_table :protector_ids
  end
end
