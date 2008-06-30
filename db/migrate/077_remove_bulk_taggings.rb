# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class RemoveBulkTaggings < ActiveRecord::Migration
  def self.up
    drop_table :bulk_taggings
  end

  def self.down
    create_table :bulk_taggings do |t|
      t.column :filter_type, :string
      t.column :filter_value, :string
      t.column :created_on, :datetime
    end
  end
end
