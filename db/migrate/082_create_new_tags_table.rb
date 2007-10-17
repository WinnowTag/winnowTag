# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class CreateNewTagsTable < ActiveRecord::Migration
  def self.up
    rename_table :tags, :old_tags
    
    create_table :tags do |t|
      t.column :name, :string, :null => false
      t.column :user_id, :integer, :null => false
      t.column :public, :boolean
      t.column :bias, :float
      t.column :created_on, :datetime
      t.column :updated_on, :datetime
    end
    
    # Make name case sensitive
    execute "ALTER TABLE `tags` MODIFY COLUMN `name` VARCHAR(255)" +
              " CHARACTER SET latin1 COLLATE latin1_general_cs DEFAULT NULL;"
    add_index :tags, [:user_id, :name], :unique => true
  end

  def self.down
    drop_table :tags
    rename_table :old_tags, :tags
  end
end
