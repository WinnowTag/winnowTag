# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class RemoveTagGroups < ActiveRecord::Migration
  def self.up
    remove_column :tag_publications, :tag_group_id
    drop_table :tag_groups
  end

  def self.down
    create_table :tag_groups do |t|
      t.column :name, :string
      t.column :description, :text
      t.column :owner_id, :integer
      t.column :global, :boolean, :default => false
      t.column :publically_readable, :boolean, :default => false
      t.column :publically_writeable, :boolean, :default => false
      t.column :created_on, :datetime
      t.column :updated_on, :datetime
    end
    add_column :tag_publications, :tag_group_id, :integer
  end
end
