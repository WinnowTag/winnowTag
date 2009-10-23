# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      t.integer :user_id
      t.text :body

      t.timestamps
    end
  end

  def self.down
    drop_table :messages
  end
end
