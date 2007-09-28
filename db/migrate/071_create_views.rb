# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
class CreateViews < ActiveRecord::Migration
  def self.up
    create_table :views do |t|
      t.column :name, :string
      t.column :user_id, :integer
    end
  end

  def self.down
    drop_table :views
  end
end
