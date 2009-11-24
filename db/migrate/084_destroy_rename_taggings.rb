# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class DestroyRenameTaggings < ActiveRecord::Migration
  def self.up
    drop_table :rename_taggings
  end

  def self.down
    create_table :rename_taggings do |t|
      t.column :old_tag_id, :integer, :null => false
      t.column :new_tag_id, :integer, :null => false
      t.column :tagger_id, :integer, :null => false
      t.column :tagger_type, :string, :null => false
      t.column :number_renamed, :integer, :null => false
      t.column :number_left, :integer, :null => false
      t.column :created_on, :datetime, :null => false
    end
  end
end
