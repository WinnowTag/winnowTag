# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class RemoveTagPublications < ActiveRecord::Migration
  def self.up
    drop_table :tag_publications    
  end

  def self.down
    create_table :tag_publications do |t|
      t.column :publisher_id, :integer
      t.column :tag_id, :integer
      t.column :comment, :text
      t.column :created_on, :datetime
    end
  end
end
