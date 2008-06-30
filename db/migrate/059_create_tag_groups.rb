# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class CreateTagGroups < ActiveRecord::Migration
  def self.up
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
  end

  def self.down
    drop_table :tag_groups
  end
end
