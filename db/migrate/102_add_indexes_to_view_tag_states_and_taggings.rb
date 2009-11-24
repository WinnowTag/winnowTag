# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class AddIndexesToViewTagStatesAndTaggings < ActiveRecord::Migration
  def self.up
    add_index :view_tag_states, :tag_id
    add_index :taggings, [:tag_id, :classifier_tagging, :strength]
    add_index :taggings, [:tag_id, :classifier_tagging]
    add_index :taggings, [:tag_id, :created_on]
  end

  def self.down
    remove_index :view_tag_states, :tag_id
    remove_index :taggings, [:tag_id, :classifier_tagging, :strength]
    remove_index :taggings, [:tag_id, :classifier_tagging]
    remove_index :taggings, [:tag_id, :created_on]
  end
end
