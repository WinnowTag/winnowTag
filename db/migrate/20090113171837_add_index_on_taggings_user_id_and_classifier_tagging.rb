# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class AddIndexOnTaggingsUserIdAndClassifierTagging < ActiveRecord::Migration
  def self.up
    add_index :taggings, [:user_id, :classifier_tagging]
  end

  def self.down
    remove_index :taggings, [:user_id, :classifier_tagging]
  end
end
