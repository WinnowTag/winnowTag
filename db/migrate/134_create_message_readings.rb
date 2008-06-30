# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class CreateMessageReadings < ActiveRecord::Migration
  def self.up
    create_table :message_readings do |t|
      t.integer :message_id
      t.integer :user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :message_readings
  end
end
