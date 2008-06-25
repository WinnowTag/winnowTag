# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class CreateTagExclusions < ActiveRecord::Migration
  def self.up
    create_table :tag_exclusions do |t|
      t.integer :tag_id
      t.integer :user_id
    end
  end

  def self.down
    drop_table :tag_exclusions
  end
end
