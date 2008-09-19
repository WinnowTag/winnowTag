# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.


class RemoveSessionsTable < ActiveRecord::Migration
  def self.up
    drop_table :sessions    
  end

  def self.down
    create_table :sessions, :options => 'ENGINE=MyISAM' do |t|
      t.column :session_id, :string
      t.column :data,       :text
      t.column :created_at, :timestamp
      t.column :updated_at, :timestamp
    end
    add_index :sessions, :session_id, :name => 'session_id_idx'
  end
end
