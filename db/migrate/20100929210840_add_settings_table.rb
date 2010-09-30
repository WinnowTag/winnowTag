# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

class AddSettingsTable < ActiveRecord::Migration
  def self.up
    create_table :settings, :force => true do |t|
      t.string :var, :null => false
      t.text   :value, :null => true
      t.integer :object_id, :null => true
      t.string :object_type, :limit => 30, :null => true
      t.timestamps
    end
    
    add_index :settings, [ :object_type, :object_id, :var ], :unique => true
  end

  def self.down
    drop_table :settings
  end
end
