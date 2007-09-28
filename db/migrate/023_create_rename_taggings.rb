# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
class CreateRenameTaggings < ActiveRecord::Migration
  def self.up
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

  def self.down
    drop_table :rename_taggings
  end
end
